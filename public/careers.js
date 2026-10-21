export function careerLessons(mode) {
 return [
 {id:`${mode.id}-words`,mode:mode.id,kind:'words',title:mode.name+'核心词汇',sub:'8 个高频词 · 听读与练习',tag:'职业词汇',icon:mode.icon,color:'green',questions:mode.words.map((w,i)=>({type:i===2?'listen':'choice',prompt:i===2?'听一听，选择这个表达的含义':`「${w.term}」是什么意思？`,english:i===2?w.example:w.term,options:[w.meaning,...mode.words.filter(x=>x.id!==w.id).slice(i%3,i%3+2).map(x=>x.meaning)].sort((a,b)=>a.localeCompare(b,'zh')),answer:w.meaning,explain:`${w.term}：${w.meaning}。${w.example}（${w.translation}）`}))},
 {id:`${mode.id}-grammar`,mode:mode.id,kind:'grammar',title:mode.name+'实用语法',sub:'3 个句型 · 从理解到应用',tag:'场景语法',icon:'✦',color:'peach',questions:mode.grammar.map(g=>({type:'choice',prompt:g.prompt,english:g.pattern,options:g.options,answer:g.answer,explain:g.explanation+' 例如：'+g.example}))},
 {id:`${mode.id}-scene`,mode:mode.id,kind:'scene',title:mode.name+'情景练习',sub:mode.subtitle,tag:'听力与表达',icon:'◉',color:'yellow',questions:mode.dialogue.slice(0,3).map(d=>({type:'listen',prompt:'听一听，这句话的意思是？',english:d.english,options:[d.translation,...mode.dialogue.filter(x=>x.english!==d.english).slice(0,2).map(x=>x.translation)],answer:d.translation,explain:`${d.english}：${d.translation}`}))}
 ];
}
export function recommendCareer(state,mode,lessons) {
 const ids=new Set(lessons.map(l=>l.id));const mistakes=state.mistakes.filter(m=>m.modeID===mode.id||ids.has(m.lessonId));
 if(mistakes.length)return {id:'review',title:mode.name+' · 先巩固，再向前',description:`本模式有 ${mistakes.length} 道错题，复习后再学习新内容。`};
 const l=lessons.find(l=>!state.completed.includes(l.id))||lessons[0];return {id:l.id,title:l.title,description:mode.subtitle+'。把学到的英语，用进你的日常。'};
}
