import test from 'node:test';
import assert from 'node:assert/strict';
import {freshState,lessons,streak,localDay,finishLesson,correctAnswer,recommend} from '../public/core.js';
test('原创课程至少覆盖选择、听力与输入题，正确答案有效',()=>{
 assert.equal(lessons.length,3);const types=new Set();
 for(const lesson of lessons)for(const q of lesson.questions){types.add(q.type);assert.ok(q.answer);if(q.options)assert.ok(q.options.includes(q.answer));assert.ok(correctAnswer(q,q.answer));assert.equal(correctAnswer(q,'错误答案'),false);}
 assert.deepEqual([...types].sort(),['choice','input','listen']);
});
test('日期使用设备本地日历；跨月连续学习与昨天续签正确',()=>{
 const now=new Date(2026,10,1,12);assert.equal(localDay(now),'2026-11-01');
 assert.equal(streak(['2026-10-30','2026-10-31','2026-11-01'],now),3);
 assert.equal(streak(['2026-10-30','2026-10-31'],now),2);
 assert.equal(streak(['2026-10-29'],now),0);
 assert.equal(streak(['2026-11-01','2026-11-01'],now),1);
});
test('学习结算：达到60%完成，XP和每日进度累加，日期和课程去重',()=>{
 const date=new Date(2026,9,21,12);let state=finishLesson(freshState(),'hello',2,5,date);
 assert.equal(state.xp,10);assert.deepEqual(state.completed,[]);
 state=finishLesson(state,'hello',3,5,date);
 assert.equal(state.xp,25);assert.equal(state.daily['2026-10-21'],25);assert.deepEqual(state.completed,['hello']);assert.equal(state.days.length,1);
 state=finishLesson(state,'hello',5,5,date);assert.deepEqual(state.completed,['hello']);
});
test('错题优先推荐；完成后推荐下一课；答题忽略大小写与句末标点',()=>{
 const state=freshState();assert.equal(recommend(state).id,'hello');state.completed=['hello'];assert.equal(recommend(state).id,'cafe');state.mistakes=[{question:lessons[0].questions[0]}];assert.equal(recommend(state).id,'review');assert.ok(correctAnswer({answer:'Name'},' name. '));
});
test('AI 课程必须有可判分题目，拒绝空课程与不匹配的答案',async()=>{
 const {validateCourse}=await import('../public/core.js');
 const source={...lessons[0]};assert.equal(validateCourse(source).questions.length,5);
 assert.throws(()=>validateCourse({title:'错误课程',questions:[]}));
 assert.throws(()=>validateCourse({...source,questions:source.questions.map(q=>({...q,answer:'不存在的选项'}))}));
});
