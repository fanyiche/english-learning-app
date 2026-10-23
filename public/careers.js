// 与 iOS 版 Models.swift 保持同一套出题规则：顶层内容是第 1 单元，units 是扩展单元。
const hash=s=>[...s].reduce((h,c)=>(h*31+c.codePointAt(0))&0x7fffffff,7);
const rotate=(items,seed)=>{if(!items.length)return items;const o=hash(seed)%items.length;return [...items.slice(o),...items.slice(0,o)];};
function pick(answer,candidates,seed){const r=[];for(const v of candidates)if(v!==answer&&!r.includes(v)&&r.length<2)r.push(v);r.splice(hash(seed)%(r.length+1),0,answer);return r;}
export const careerUnits=mode=>[{id:mode.id,title:'基础核心',level:null,words:mode.words,grammar:mode.grammar,dialogue:mode.dialogue},...(mode.units||[])];
export const allWords=mode=>careerUnits(mode).flatMap(u=>u.words);
export const allDialogue=mode=>careerUnits(mode).flatMap(u=>u.dialogue);
export const drills=['meaning','listen','term','cloze','spell'];
export function wordQuestion(mode,word,drill){
 const explain=`${word.term}：${word.meaning}。${word.example}（${word.translation}）`;
 const same=(careerUnits(mode).find(u=>u.words.some(w=>w.id===word.id))?.words||[]).filter(w=>w.id!==word.id);
 const pool=[...rotate(same,word.id),...rotate(allWords(mode).filter(w=>w.id!==word.id&&!same.includes(w)),word.id)];
 const meanings=pick(word.meaning,pool.map(w=>w.meaning),word.id),terms=pick(word.term,pool.map(w=>w.term),word.id);
 const base={answer:word.term,explain,wordID:word.id};
 if(drill==='meaning')return {...base,type:'choice',prompt:`「${word.term}」是什么意思？`,english:word.term,options:meanings,answer:word.meaning};
 if(drill==='listen')return {...base,type:'listen',prompt:'听一听，选择这个表达的含义',english:word.example,options:meanings,answer:word.meaning};
 if(drill==='spell')return {...base,type:'input',prompt:`拼写「${word.meaning}」的英文`};
 const at=word.example.toLowerCase().indexOf(word.term.toLowerCase());
 if(drill==='cloze'&&at>=0)return {...base,type:'choice',prompt:'选词填空：'+word.translation,english:word.example.slice(0,at)+'____'+word.example.slice(at+word.term.length),options:terms};
 return {...base,type:'choice',prompt:`「${word.meaning}」用英语怎么说？`,options:terms};
}
export function unitLessons(mode,unit){
 const lines=allDialogue(mode),cycle=['meaning','term','listen','cloze'];
 return [
 {id:`${unit.id}-words`,mode:mode.id,unit:unit.id,kind:'words',title:unit.title+' · 词汇',sub:`${unit.words.length} 个词 · 听读与练习`,tag:'职业词汇',icon:mode.icon,color:'green',questions:unit.words.map((w,i)=>wordQuestion(mode,w,cycle[i%cycle.length]))},
 {id:`${unit.id}-grammar`,mode:mode.id,unit:unit.id,kind:'grammar',title:unit.title+' · 语法',sub:`${unit.grammar.length} 个句型 · 从理解到应用`,tag:'场景语法',icon:'✦',color:'peach',questions:unit.grammar.map(g=>({type:'choice',prompt:g.prompt,english:g.pattern,options:g.options,answer:g.answer,explain:g.explanation+' 例如：'+g.example}))},
 {id:`${unit.id}-scene`,mode:mode.id,unit:unit.id,kind:'scene',title:unit.title+' · 情景听力',sub:'听力与表达',tag:'听力与表达',icon:'◉',color:'yellow',questions:unit.dialogue.map(d=>({type:'listen',prompt:'听一听，这句话的意思是？',english:d.english,options:pick(d.translation,[...unit.dialogue,...lines].filter(x=>x.english!==d.english).map(x=>x.translation),d.english),answer:d.translation,explain:`${d.english}：${d.translation}`}))}
 ];
}
export const careerLessons=mode=>unitLessons(mode,careerUnits(mode)[0]);
export const allCareerLessons=mode=>careerUnits(mode).flatMap(u=>unitLessons(mode,u));
export function recommendCareer(state,mode,lessons) {
 const ids=new Set(lessons.map(l=>l.id));const mistakes=state.mistakes.filter(m=>m.modeID===mode.id||ids.has(m.lessonId));
 if(mistakes.length)return {id:'review',title:mode.name+' · 先巩固，再向前',description:`本模式有 ${mistakes.length} 道错题，复习后再学习新内容。`};
 const l=lessons.find(l=>!state.completed.includes(l.id))||lessons[0];return {id:l.id,title:l.title,description:mode.subtitle+'。把学到的英语，用进你的日常。'};
}
