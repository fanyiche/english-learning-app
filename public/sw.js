const CACHE='lingo-garden-v5';
// 相对路径：网站可以部署在子目录（如 GitHub Pages 的 /english-learning-app/）。
const ASSETS=['./','index.html','style.css','app.js','core.js','careers.js','careers.json','manifest.webmanifest','icon.svg','icon-192.png','icon-512.png','apple-touch-icon.png'];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS))));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('lingo-garden-')&&k!==CACHE).map(k=>caches.delete(k))))));
self.addEventListener('fetch',e=>{if(e.request.method!=='GET'||new URL(e.request.url).origin!==self.location.origin||new URL(e.request.url).pathname.includes('/api/'))return;e.respondWith(fetch(e.request.url,{cache:'no-cache'}).then(r=>{if(r.ok){const copy=r.clone();e.waitUntil(caches.open(CACHE).then(c=>c.put(e.request,copy)));}return r;}).catch(()=>caches.match(e.request).then(c=>c||(e.request.mode==='navigate'?caches.match('./'):new Response('Offline',{status:503})))));});
