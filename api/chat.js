export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: { message: 'Method not allowed' } });

  // تحقق من الـ key
  const key = process.env.OPENROUTER_KEY;
  if (!key) {
    return res.status(500).json({ error: { message: 'OPENROUTER_KEY not set in Vercel environment variables' } });
  }

  try {
    const { messages, system } = req.body;

    const orRes = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${key}`,
        'HTTP-Referer': 'https://ops-dashboard-kappa-two.vercel.app',
        'X-Title': 'Ops Dashboard AI'
      },
      body: JSON.stringify({
        model: 'mistralai/mistral-7b-instruct:free',
        max_tokens: 1200,
        temperature: 0.3,
        messages: [
          { role: 'system', content: system },
          ...messages
        ]
      })
    });

    const data = await orRes.json();
    if (data.error) return res.status(400).json({ error: { message: data.error.message } });

    const text = data.choices?.[0]?.message?.content || '—';
    return res.status(200).json({ content: [{ text }] });

  } catch (err) {
    return res.status(500).json({ error: { message: err.message } });
  }
}
