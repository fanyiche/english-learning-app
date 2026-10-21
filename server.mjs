import http from 'node:http';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
const root = path.join(import.meta.dirname, 'public');
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8', '.webmanifest': 'application/manifest+json' };
const model = process.env.OLLAMA_MODEL || 'qwen2.5:3b';
const json = (res, code, data) => { res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' }); res.end(JSON.stringify(data)); };
http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  if (url.pathname === '/api/ai/status') {
    try {
      const response = await fetch('http://127.0.0.1:11434/api/tags', { signal: AbortSignal.timeout(2000) });
      if (!response.ok) throw Error();
      const { models = [] } = await response.json();
      json(res, 200, { available: models.some(m => m.name === model || m.name === `${model}:latest`), model });
    } catch { json(res, 200, { available: false, model }); }
    return;
  }
  if (url.pathname === '/api/ai' && req.method === 'POST') {
    try {
      let body = '';
      for await (const chunk of req) { body += chunk; if (Buffer.byteLength(body) > 16000) { json(res, 413, { error: '消息过长' }); return; } }
      const { messages, mode = 'chat', mistakes = [], level = '零基础', career = '学生' } = JSON.parse(body);
      if (!Array.isArray(messages) || !messages.length || messages.length > 16 || messages.some(m => !['user', 'assistant'].includes(m.role) || typeof m.content !== 'string' || m.content.length > 3000)) {
        json(res, 400, { error: '无效的对话内容' }); return;
      }
      const system = `You are Fern, a warm English tutor for Chinese beginners. Explain grammar briefly in Chinese with original English examples. For roleplay, speak simple English and ask one question at a time. Mode: ${String(mode).slice(0,60)}. Student profession/learning mode: ${String(career).slice(0,60)}. Use vocabulary, grammar and roleplays relevant to this profession. Student level: ${String(level).slice(0,30)}. Student mistakes: ${JSON.stringify(mistakes).slice(0,1000)}. When mode is course, return ONLY a JSON object with title (Chinese string), sub (Chinese string), questions (3 to 5 objects). Each question must have type (choice, input, or listen), prompt (Chinese), answer (exact correct option or single English word for input), explain (Chinese explanation), english (English sentence when needed). choice and listen questions must have options (3 distinct strings including the exact answer); listen MUST have english. Adapt questions to the student's mistakes and requested topic. Otherwise respond conversationally, never JSON. Never claim to have evaluated audio.`;
      const response = await fetch('http://127.0.0.1:11434/api/chat', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ model, stream: false, ...(mode === 'course' ? {format:'json'} : {}), messages: [{ role: 'system', content: system }, ...messages] }), signal: AbortSignal.timeout(120000) });
      if (!response.ok) throw Error('model unavailable');
      const result = await response.json();
      if (!result.message?.content) throw Error('empty model response');
      json(res, 200, { content: result.message.content, source: 'local-model' });
    } catch (error) { json(res, error instanceof SyntaxError ? 400 : 503, { error: error instanceof SyntaxError ? '请求格式错误' : '本地 AI 尚未连接。请启动 Ollama 并安装所选模型；你仍可使用离线课程与练习。' }); }
    return;
  }
  if (url.pathname.startsWith('/api/')) { json(res, 404, { error: 'Not found' }); return; }
  if (!['GET', 'HEAD'].includes(req.method)) { res.writeHead(405); res.end(); return; }
  try {
    const file = path.resolve(root, '.' + decodeURIComponent(url.pathname === '/' ? '/index.html' : url.pathname));
    if (!file.startsWith(root + path.sep)) { res.writeHead(403); res.end(); return; }
    const data = await readFile(file);
    res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream', 'X-Content-Type-Options': 'nosniff' }); res.end(req.method === 'HEAD' ? undefined : data);
  } catch { res.writeHead(404); res.end('Not found'); }
}).listen(Number(process.env.PORT || 3000), '0.0.0.0', () => console.log('Lingo Garden running on port ' + (process.env.PORT || 3000)));
