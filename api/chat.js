export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: { message: 'Method not allowed' } });

  try {
    const { messages, system, key } = req.body;

    if (!key) return res.status(400).json({ error: { message: 'No API key provided' } });

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${key}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          system_instruction: { parts: [{ text: system }] },
          contents: messages.map(m => ({
            role: m.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: m.content }]
          })),
          generationConfig: { maxOutputTokens: 1000, temperature: 0.3 }
        })
      }
    );

    const data = await geminiRes.json();
    if (data.error) return res.status(400).json({ error: { message: data.error.message } });

    const text = data.candidates?.[0]?.content?.parts?.[0]?.text || '—';
    return res.status(200).json({ content: [{ text }] });

  } catch (err) {
    return res.status(500).json({ error: { message: err.message } });
  }
}
