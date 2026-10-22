import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {careerLessons,recommendCareer} from '../public/careers.js';
import {freshState,correctAnswer,validateCourse} from '../public/core.js';
const raw=await readFile(new URL('../public/careers.json',import.meta.url),'utf8');
const careers=JSON.parse(raw);
test('每个身份的基础单元各有八个词、三个语法点、完整情景，iOS 与网页共享相同内容',async()=>{
 assert.deepEqual(careers.map(c=>c.id),['student','lawyer','restaurant','healthcare','business','life']);
 const ids=new Set();for(const c of careers){assert.equal(c.words.length,8);assert.equal(c.grammar.length,3);assert.ok(c.dialogue.length>=4);
 for(const w of c.words){assert.ok(w.term&&w.meaning&&w.example&&w.translation);assert.ok(!ids.has(w.id));ids.add(w.id);}
 for(const g of c.grammar){assert.ok(g.pattern&&g.explanation&&g.example&&g.translation);assert.ok(g.options.includes(g.answer));assert.equal(new Set(g.options).size,g.options.length);}}
 assert.equal(await readFile(new URL('../ios/LingoGarden/careers.json',import.meta.url),'utf8'),raw);
});
test('职业课程均有可判分且唯一的正确选项，覆盖词汇语法和情景',()=>{
 const ids=new Set();for(const c of careers){const lessons=careerLessons(c);assert.equal(lessons.length,3);for(const l of lessons){assert.ok(!ids.has(l.id));ids.add(l.id);assert.equal(l.mode,c.id);validateCourse(l);for(const q of l.questions){assert.ok(correctAnswer(q,q.answer));assert.equal(q.options.filter(o=>o===q.answer).length,1);assert.equal(new Set(q.options).size,q.options.length);}}}
});
test('个性化路径只选择当前模式：他人错题不混入，切换进度不丢失',()=>{
 const state=freshState();const student=careers[0],restaurant=careers[2];const studentLessons=careerLessons(student),restaurantLessons=careerLessons(restaurant);
 state.completed=[studentLessons[0].id];state.mistakes=[{lessonId:studentLessons[1].id,question:studentLessons[1].questions[0]}];
 assert.equal(recommendCareer(state,student,studentLessons).id,'review');assert.equal(recommendCareer(state,restaurant,restaurantLessons).id,'restaurant-words');
 state.mistakes=[];assert.equal(recommendCareer(state,student,studentLessons).id,'student-grammar');assert.deepEqual(state.completed,['student-words']);
});
test('扩展单元：每单元足量内容，同一身份内单词与释义唯一，例句可出填空题',()=>{
 const ids=new Set();
 for(const c of careers){const units=[{id:c.id,words:c.words,grammar:c.grammar,dialogue:c.dialogue},...(c.units||[])];assert.ok(units.length>=5);
  const terms=new Set(),meanings=new Set();
  for(const u of units){assert.ok(u.words.length>=6&&u.grammar.length>=2&&u.dialogue.length>=4,u.id);
   for(const w of u.words){assert.ok(!ids.has(w.id),w.id);ids.add(w.id);
    assert.ok(!terms.has(w.term.toLowerCase()),w.term);terms.add(w.term.toLowerCase());
    assert.ok(!meanings.has(w.meaning),w.meaning);meanings.add(w.meaning);
    assert.ok(w.example.toLowerCase().includes(w.term.toLowerCase()),w.term);}
   for(const g of u.grammar){assert.ok(!ids.has(g.id),g.id);ids.add(g.id);assert.ok(g.options.includes(g.answer),g.id);assert.equal(new Set(g.options).size,g.options.length);}}}
});
