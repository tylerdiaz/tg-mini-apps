#!/usr/bin/env node
/**
 * Sync quests from markdown files to embedded JSON in index.html
 * Run: node sync.js
 */

const fs = require('fs');
const path = require('path');

const QUESTS_DIR = path.join(__dirname, '../../spectrum/quests');
const HTML_FILE = path.join(__dirname, 'index.html');

function parseQuestMarkdown(content, questId, topic) {
  const quest = {
    id: questId,
    topic: topic,
    title: '',
    status: 'active',
    priority: 'P2',
    created: '',
    updated: '',  // Will be computed from logs
    collaborator: null,
    pingcode_ticket: null,
    obsidian_note: null,
    prs: [],
    context: '',
    log: [],
    assets: []
  };

  // Parse title (support both formats)
  const titleMatch = content.match(/^# (?:Quest: )?(.+)$/m);
  if (titleMatch) quest.title = titleMatch[1].trim();

  // Parse frontmatter-style fields (multiple formats)
  // Status: 🔍 investigating | 🟢 ready | 🔵 active | 🟡 blocked | ✅ done
  const statusLine = content.match(/\*\*Status:\*\* .+$/m);
  if (statusLine) {
    const statusText = statusLine[0].toLowerCase();
    if (statusText.includes('investigating')) quest.status = 'investigating';
    else if (statusText.includes('ready')) quest.status = 'ready';
    else if (statusText.includes('active')) quest.status = 'active';
    else if (statusText.includes('blocked')) quest.status = 'blocked';
    else if (statusText.includes('done')) quest.status = 'done';
    else if (statusText.includes('paused')) quest.status = 'paused';
  }

  // Priority
  const priorityMatch = content.match(/\*\*Priority:\*\* (P[0-3])/);
  if (priorityMatch) quest.priority = priorityMatch[1];

  const createdMatch = content.match(/\*\*Created:\*\* ([\d-]+)/);
  if (createdMatch) quest.created = createdMatch[1];

  const collabMatch = content.match(/\*\*(?:Collaborator|With):\*\* (.+)$/m);
  if (collabMatch) quest.collaborator = collabMatch[1].trim();

  // Parse PingCode ticket
  const pingcodeMatch = content.match(/\*\*PingCode:\*\* ([A-Z]+-\d+)/);
  if (pingcodeMatch) quest.pingcode_ticket = pingcodeMatch[1];

  // Parse Obsidian note reference
  const obsidianMatch = content.match(/\*\*Obsidian:\*\* (.+)$/m);
  if (obsidianMatch) quest.obsidian_note = obsidianMatch[1].trim();

  // Parse linked PRs (for display)
  const prs = [];
  const prMatches = content.matchAll(/(?:^|\s)#(\d+)\s*[—–-]\s*(.+?)(?:\n|$)/gm);
  for (const match of prMatches) {
    prs.push({ number: parseInt(match[1]), title: match[2].trim() });
  }
  if (prs.length > 0) quest.prs = prs;

  // Parse context
  const contextMatch = content.match(/## Context\n+(.+?)(?=\n##|\n\*\*|$)/s);
  if (contextMatch) quest.context = contextMatch[1].trim();

  // Parse log entries and track last update
  let lastLogDate = null;
  const logSection = content.match(/## Log\n([\s\S]*?)(?=\n## |$)/);
  if (logSection) {
    const logContent = logSection[1];
    const dayMatches = logContent.matchAll(/### ([\d-]+)\n([\s\S]*?)(?=\n###|$)/g);
    for (const match of dayMatches) {
      const date = match[1];
      const entries = match[2]
        .split('\n')
        .filter(line => line.startsWith('- '))
        .map(line => line.slice(2).trim());
      if (entries.length > 0) {
        quest.log.push({ date, entries });
        // Track most recent log date
        if (!lastLogDate || date > lastLogDate) {
          lastLogDate = date;
        }
      }
    }
  }

  // Set updated to last log date, or created if no logs
  quest.updated = lastLogDate || quest.created;

  return quest;
}

function loadQuests() {
  const quests = [];
  const topics = ['dev', 'growth', 'ux', 'ops'];

  for (const topic of topics) {
    const topicDir = path.join(QUESTS_DIR, topic);
    if (!fs.existsSync(topicDir)) continue;

    const items = fs.readdirSync(topicDir, { withFileTypes: true });
    
    for (const item of items) {
      if (!item.isDirectory()) continue;
      
      const questDir = path.join(topicDir, item.name);
      const questFile = path.join(questDir, 'quest.md');
      const assetsDir = path.join(questDir, 'assets');
      
      if (!fs.existsSync(questFile)) continue;
      
      const content = fs.readFileSync(questFile, 'utf8');
      const quest = parseQuestMarkdown(content, item.name, topic);
      
      // Load assets
      if (fs.existsSync(assetsDir)) {
        const assetFiles = fs.readdirSync(assetsDir);
        quest.assets = assetFiles.map(f => {
          const ext = path.extname(f).toLowerCase();
          const isImage = ['.png', '.jpg', '.jpeg', '.gif', '.webp'].includes(ext);
          const isAudio = ['.ogg', '.mp3', '.m4a', '.wav'].includes(ext);
          const isPdf = ext === '.pdf';
          return {
            name: f,
            path: `${topic}/${item.name}/assets/${f}`,
            type: isImage ? 'image' : isAudio ? 'audio' : isPdf ? 'pdf' : 'file'
          };
        });
      }
      
      quests.push(quest);
    }
  }

  return quests;
}

function updateHtml(quests) {
  let html = fs.readFileSync(HTML_FILE, 'utf8');
  
  // Replace the QUESTS array
  const questsJson = JSON.stringify(quests, null, 2)
    .split('\n')
    .map((line, i) => i === 0 ? line : '      ' + line)
    .join('\n');
  
  html = html.replace(
    /const QUESTS = \[[\s\S]*?\];/,
    `const QUESTS = ${questsJson};`
  );

  fs.writeFileSync(HTML_FILE, html);
  console.log(`✓ Synced ${quests.length} quests to index.html`);
  
  // Summary by status
  const byStatus = {};
  quests.forEach(q => {
    byStatus[q.status] = (byStatus[q.status] || 0) + 1;
  });
  console.log('  Status:', Object.entries(byStatus).map(([k,v]) => `${k}: ${v}`).join(', '));
  
  quests.forEach(q => {
    const assetCount = q.assets?.length || 0;
    const logCount = q.log.reduce((sum, day) => sum + day.entries.length, 0);
    console.log(`  - ${q.topic}/${q.id}: ${q.status}, ${logCount} logs, updated ${q.updated}`);
  });
}

const quests = loadQuests();
updateHtml(quests);
