// Cloudflare Worker to receive Mini App form submissions
// and forward them to Telegram bot

const BOT_TOKEN = 'YOUR_BOT_TOKEN'; // We'll set this as a secret
const CHAT_ID = '1519264541'; // Tyler's chat ID

export default {
  async fetch(request, env) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    try {
      const data = await request.json();
      
      // Format the message
      const message = `📋 **Mini App Submission**\n\n` +
        Object.entries(data.data || data)
          .map(([k, v]) => `**${k}:** ${v}`)
          .join('\n');

      // Send to Telegram
      const telegramUrl = `https://api.telegram.org/bot${env.BOT_TOKEN || BOT_TOKEN}/sendMessage`;
      const telegramResponse = await fetch(telegramUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: data.chatId || CHAT_ID,
          text: message,
          parse_mode: 'Markdown',
        }),
      });

      const result = await telegramResponse.json();
      
      return new Response(JSON.stringify({ ok: true, result }), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    } catch (err) {
      return new Response(JSON.stringify({ ok: false, error: err.message }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }
  },
};
