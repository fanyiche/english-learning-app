import {mkdir} from 'node:fs/promises';
await mkdir('test-results',{recursive:true});
import {chromium} from 'playwright';
import assert from 'node:assert/strict';
const browser=await chromium.launch({...(process.env.CHROMIUM_PATH?{executablePath:process.env.CHROMIUM_PATH}:{}),headless:true,args:['--no-sandbox']});
const context=await browser.newContext({viewport:{width:393,height:852},deviceScaleFactor:2,isMobile:true,hasTouch:true});
const page=await context.newPage();const errors=[];
page.on('pageerror',e=>errors.push(e.message));
await page.goto(process.env.TEST_BASE_URL||'http://localhost:3000');await page.evaluate(()=>localStorage.clear());await page.reload();await page.waitForSelector('.hero');
await page.screenshot({path:'test-results/mobile.png',fullPage:true});
assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true,'No mobile overflow');
await page.locator('.bottom-nav [data-page="learn"]').click();await page.locator('.foundation summary').click();await page.locator('[data-lesson="hello"]').click();
await page.locator('[data-answer="再见，明天见。"] ').click();await page.locator('#submit-answer').click();await page.waitForTimeout(100);
assert.match(await page.locator('#answer-feedback').textContent(),/正确答案/);await page.locator('#submit-answer').click();await page.waitForTimeout(100);
for(const answer of ['I am Lily.','你今天怎么样？']){await page.locator('[data-answer]').filter({hasText:answer}).click();await page.locator('#submit-answer').click();await page.waitForTimeout(100);await page.locator('#submit-answer').click();await page.waitForTimeout(100);}
await page.locator('#typed-answer').fill('name');await page.locator('#submit-answer').click();await page.waitForTimeout(100);await page.locator('#submit-answer').click();await page.waitForTimeout(100);
await page.locator('[data-answer]').filter({hasText:'I’m fine, thank you.'}).click();await page.locator('#submit-answer').click();await page.waitForTimeout(100);await page.locator('#submit-answer').click();await page.waitForTimeout(100);
assert.match(await page.locator('.result-xp').textContent(),/20/);await page.locator('#done').click();
let state=await page.evaluate(()=>JSON.parse(localStorage.getItem('lingo-garden')));assert.equal(state.xp,20);assert.equal(state.mistakes.length,1);assert.deepEqual(state.completed,['hello']);
await page.reload();assert.match(await page.locator('.hero h2').textContent(),/巩固/);await page.locator('.hero [data-lesson]').click();
await page.locator('[data-answer]').filter({hasText:'你好！很高兴认识你。'}).click();await page.locator('#submit-answer').click();await page.waitForTimeout(100);await page.locator('#submit-answer').click();await page.waitForTimeout(100);await page.locator('#done').click();
state=await page.evaluate(()=>JSON.parse(localStorage.getItem('lingo-garden')));assert.equal(state.mistakes.length,0);assert.equal(state.xp,25);
for(const p of ['learn','speak','ai','profile']){await page.locator(`.bottom-nav [data-page="${p}"]`).click();assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true,p+' no overflow');}
await page.locator('#settings input').fill('小林');await page.locator('#settings select[name="goal"]').selectOption('30');await page.locator('#settings button').click();
assert.match(await page.locator('#toast').textContent(),/已保存/);await page.reload();assert.equal(await page.locator('#app').textContent().then(t=>t.includes('小林')),true);
await page.locator('.bottom-nav [data-page="ai"]').click();assert.match(await page.locator('.ai-status').textContent(),/未连接/);
await page.locator('[data-prompt]').first().click();await page.locator('#chat-form button').click();assert.match(await page.locator('#toast').textContent(),/未连接/);
// Test the UI contract with a simulated model; this does not validate real inference.
await page.route('**/api/ai/status',route=>route.fulfill({json:{available:true,model:'test-model'}}));
await page.locator('#refresh-ai').click();await page.waitForSelector('.ai-status.connected');
await page.route('**/api/ai',async route=>{
 const payload=route.request().postDataJSON();assert.equal(payload.mode,'course');assert.equal(payload.level,'零基础');
 const {lessons}=await import('../public/core.js');
 await route.fulfill({json:{content:JSON.stringify({...lessons[1],title:'测试生成课程 <script>alert(1)</script>'}),source:'local-model'}});
});
await page.locator('[data-mode="course"]').click();await page.locator('#chat-input').fill('生成旅行英语课');await page.locator('#chat-form button').click();
await page.waitForFunction(()=>JSON.parse(localStorage.getItem('lingo-garden')).generated?.length===1);
await page.locator('.bottom-nav [data-page="learn"]').click();assert.equal(await page.locator('main > .all-courses > .course-card').count(),4);
await page.locator('main > .all-courses > .course-card').last().click();assert.match(await page.locator('.modal .eyebrow').textContent(),/测试生成课程/);await page.locator('#quit').click();
await page.locator('.bottom-nav [data-page="speak"]').click();await page.locator('#speech-text').fill('Could you explain this question?');await page.locator('#check-speech').click();assert.match(await page.locator('#speech-result').textContent(),/表达一致/);
await page.locator('.bottom-nav [data-page="home"]').click();
await page.evaluate(()=>navigator.serviceWorker.ready);await page.waitForTimeout(500);await page.reload();
await context.setOffline(true);await page.reload();await page.waitForSelector('.hero');assert.match(await page.locator('h1').textContent(),/小林/);await context.setOffline(false);
await page.setViewportSize({width:1440,height:1000});await page.screenshot({path:'test-results/desktop.png',fullPage:true});
assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true,'desktop no overflow');
await page.setViewportSize({width:320,height:700});for(const p of ['home','learn','speak','ai','profile']){await page.locator(`.bottom-nav [data-page="${p}"]`).click();assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true,p+' 320px overflow');}
assert.deepEqual(errors,[]);console.log('PASS: mobile/desktop layout, 5-question lesson, scoring, mistake review, persistence, preferences, AI unavailable, text speaking practice, simulated AI course generation, offline reload, 320px layout; no JS errors.');
await browser.close();
