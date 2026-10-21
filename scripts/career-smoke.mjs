import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import {readFile,mkdir} from 'node:fs/promises';
import {careerLessons} from '../public/careers.js';
const careers=JSON.parse(await readFile(new URL('../public/careers.json',import.meta.url),'utf8'));
await mkdir('test-results',{recursive:true});
const browser=await chromium.launch({...(process.env.CHROMIUM_PATH?{executablePath:process.env.CHROMIUM_PATH}:{}),headless:true,args:['--no-sandbox']});
try {
 const context=await browser.newContext({viewport:{width:393,height:852},isMobile:true,hasTouch:true});
 const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(process.env.TEST_BASE_URL||'http://localhost:3000');await page.waitForSelector('.mode-strip');
 await page.evaluate(()=>localStorage.clear());await page.reload();
 await page.locator('.bottom-nav [data-page="learn"]').click();
 async function select(id){await page.locator('[data-switch-mode]').click();await page.locator(`[data-career="${id}"]`).click();}
 for(const c of careers){
  await select(c.id);assert.match(await page.locator('h1').textContent(),new RegExp(c.name));
  await page.locator('[data-topic="words"]').click();assert.equal(await page.locator('.word-card').count(),8);assert.match(await page.locator('.word-card').first().textContent(),new RegExp(c.words[0].term));
  await page.locator('[data-known]').first().click();assert.match(await page.locator('[data-known]').first().textContent(),/已掌握/);await page.locator('#close-topic').click();
  await page.locator('[data-topic="grammar"]').click();assert.equal(await page.locator('.grammar-card').count(),3);assert.match(await page.locator('.grammar-card').first().textContent(),new RegExp(c.grammar[0].title));await page.locator('#close-topic').click();
  await page.locator('[data-topic="scene"]').click();assert.equal(await page.locator('.dialogue-card').count(),c.dialogue.length);await page.locator('#close-topic').click();
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true,c.id+' no horizontal overflow');
 }
 await select('restaurant');await page.locator('[data-topic="words"]').click();await page.screenshot({path:'test-results/restaurant-vocabulary.png',fullPage:true});await page.locator('#practice-topic').click();
 const lesson=careerLessons(careers.find(c=>c.id==='restaurant'))[0];
 for(let i=0;i<lesson.questions.length;i++){
  const q=lesson.questions[i];const answer=i===0?q.options.find(o=>o!==q.answer):q.answer;
  await page.locator('[data-answer]').filter({hasText:answer}).click();await page.locator('#submit-answer').click();
  assert.match(await page.locator('#answer-feedback').textContent(),i===0?/正确答案/:/答对了/);
  await page.locator('#submit-answer').click();
 }
 assert.match(await page.locator('.result-xp').textContent(),/35/);await page.locator('#done').click();
 await select('lawyer');assert.match(await page.locator('.review-card small').textContent(),/^0 /);
 await select('restaurant');assert.match(await page.locator('.review-card small').textContent(),/^1 /);
 await page.reload();assert.match(await page.locator('.mode-strip b').textContent(),/餐馆/);
 await page.locator('.bottom-nav [data-page="learn"]').click();await page.locator('[data-topic="words"]').click();assert.match(await page.locator('[data-known]').first().textContent(),/✓ 已掌握/);await page.locator('#close-topic').click();
 await page.locator('[data-lesson="review"]').click();await page.locator('[data-answer]').filter({hasText:lesson.questions[0].answer}).click();await page.locator('#submit-answer').click();await page.locator('#submit-answer').click();await page.locator('#done').click();
 assert.match(await page.locator('.review-card small').textContent(),/^0 /);
 await page.locator('.bottom-nav [data-page="home"]').click();await page.screenshot({path:'test-results/restaurant-mobile.png',fullPage:true});
 for(const width of [320,393,768,1440]){await page.setViewportSize({width,height:852});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true,'restaurant '+width+'px');}
 await page.evaluate(()=>navigator.serviceWorker.ready);await page.reload();await context.setOffline(true);await page.reload();await page.waitForSelector('.mode-strip');await page.locator('[data-switch-mode]').click();await page.locator('[data-career="lawyer"]').click();assert.match(await page.locator('.mode-strip b').textContent(),/律师/);
 assert.deepEqual(errors,[]);
 console.log('PASS: all 5 identities, 40 vocabulary cards, 15 grammar cards, dialogues, restaurant 8-question quiz, isolated mistake review, XP, mode/word persistence, 4 screen sizes and offline mode switching.');
} finally {await browser.close();}
