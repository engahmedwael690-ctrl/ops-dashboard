// api/chat.js
export const config = {
  runtime: 'nodejs',
};

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // Only allow POST
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const { messages, model } = req.body;
    const apiKey = req.headers.authorization?.replace('Bearer ', '').trim();

    if (!apiKey) {
      res.status(401).json({ error: 'API Key is required' });
      return;
    }

    if (!messages || !Array.isArray(messages)) {
      res.status(400).json({ error: 'Messages array is required' });
      return;
    }

    // Call OpenRouter
    const openRouterRes = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://your-app.vercel.app',
        'X-Title': 'AI Assistant',
      },
      body: JSON.stringify({
        model: model || 'meta-llama/llama-3-8b-instruct:free',
        messages: messages,
        temperature: 0.7,
        max_tokens: 1024,
      }),
    });

    const data = await openRouterRes.json();

    if (!openRouterRes.ok) {
      res.status(openRouterRes.status).json({ 
        error: data.error?.message || 'OpenRouter error' 
      });
      return;
    }

    res.status(200).json(data);

  } catch (error) {
    console.error('Server Error:', error);
    res.status(500).json({ 
      error: 'Internal Server Error',
      details: error.message 
    });
  }
}