export const lessons = [
 { id:'hello', title:'从一句 Hello 开始', sub:'打招呼与自我介绍', tag:'基础英语', icon:'✦', color:'green', questions:[
 {type:'choice',prompt:'第一次见面，你会怎样打招呼？',english:'Hello! Nice to meet you.',options:['你好！很高兴认识你。','再见，明天见。','谢谢你的帮助。'],answer:'你好！很高兴认识你。',explain:'Nice to meet you 是初次见面时的礼貌表达。'},
 {type:'choice',prompt:'选择正确的自我介绍',options:['I is Lily.','I am Lily.','I are Lily.'],answer:'I am Lily.',explain:'主语 I 搭配 am；you 搭配 are；he / she 搭配 is。'},
 {type:'listen',prompt:'听一听，选择你听到的意思',english:'How are you today?',options:['你今天怎么样？','你叫什么名字？','你来自哪里？'],answer:'你今天怎么样？',explain:'How are you? 用来询问对方的近况，today 表示今天。'},
 {type:'input',prompt:'补全句子：我叫 Lily。',english:'My ___ is Lily.',answer:'name',explain:'My name is… 表示“我的名字是……”。'},
 {type:'choice',prompt:'别人问 How are you?，你可以回答',options:['I’m fine, thank you.','Good night.','My name is Tom.'],answer:'I’m fine, thank you.',explain:'I’m fine, thank you. 表示“我很好，谢谢”。'}]},
 {id:'cafe',title:'一杯咖啡的时间',sub:'在咖啡馆自然点单',tag:'生活英语',icon:'☕',color:'peach',questions:[
 {type:'listen',prompt:'听一听，客人想要什么？',english:'I would like a cup of coffee, please.',options:['一杯咖啡','一杯果汁','一杯茶'],answer:'一杯咖啡',explain:'I would like… 是礼貌点单的表达。'},
 {type:'choice',prompt:'“多少钱？”用英语怎么说？',options:['How old are you?','How much is it?','How are you?'],answer:'How much is it?',explain:'How much 用来询问价格。'},
 {type:'input',prompt:'补全句子：一杯茶，谢谢。',english:'A cup of ___, please.',answer:'tea',explain:'tea 是茶，coffee 是咖啡。'},
 {type:'choice',prompt:'选择更礼貌的请求',options:['Give me water.','Could I have some water, please?','Water now.'],answer:'Could I have some water, please?',explain:'Could I have… 和 please 可以让请求更礼貌。'}]},
 {id:'daily',title:'我的日常小事',sub:'用英语分享每一天',tag:'日常表达',icon:'☀',color:'yellow',questions:[
 {type:'choice',prompt:'“我每天读书。”的正确表达是',options:['I read every day.','I reads every day.','I reading every day.'],answer:'I read every day.',explain:'一般现在时表达习惯；主语 I 后用动词原形。'},
 {type:'input',prompt:'补全句子：她每天走路去学校。',english:'She ___ to school every day.',answer:'walks',explain:'一般现在时中，第三人称单数 she 后动词通常加 s。'},
 {type:'listen',prompt:'听一听，他几点起床？',english:'I get up at seven.',options:['六点','七点','八点'],answer:'七点',explain:'at seven 表示在七点。'},
 {type:'choice',prompt:'选择正确的否定句',options:['I don’t like rain.','I not like rain.','I doesn’t like rain.'],answer:'I don’t like rain.',explain:'I / you / we / they 的一般现在时否定用 don’t + 动词原形。'}]}
];
export const freshState = () => ({xp:0,completed:[],mistakes:[],days:[],daily:{},goal:20,name:'学习者',level:'零基础',generated:[],reviews:{},newPerDay:10});
export function localDay(date = new Date()) { return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`; }
export function streak(days, now = new Date()) { const seen = new Set(days); const date = new Date(now); if(!seen.has(localDay(date))) date.setDate(date.getDate()-1); let n=0; while(seen.has(localDay(date))) {n++;date.setDate(date.getDate()-1);} return n; }
// 间隔重复：答对升一级并按间隔推迟（当天已复习的词不重复升级），答错回到第一级、明天再复习。
export const intervals=[1,2,4,7,15,30,60];
const shiftDay=(days,date)=>{const d=new Date(date);d.setDate(d.getDate()+days);return localDay(d);};
export function reviewWord(state,wordID,correct,date=new Date()){
 const today=localDay(date),existing=state.reviews?.[wordID],item={...(existing||{box:0,due:today,added:today})};
 if(correct){if(existing&&item.due>today)return state;item.box=Math.min(item.box+1,intervals.length);item.due=shiftDay(intervals[item.box-1],date);}
 else{item.box=0;item.due=shiftDay(1,date);}
 return {...state,reviews:{...state.reviews,[wordID]:item}};
}
export function markKnown(state,wordID,date=new Date()){return state.reviews?.[wordID]?state:{...state,reviews:{...state.reviews,[wordID]:{box:4,due:shiftDay(intervals[3],date),added:''}}};}
export function dailyWords(state,words,date=new Date()){
 const today=localDay(date),reviews=state.reviews||{};
 const due=words.filter(w=>reviews[w.id]&&reviews[w.id].due<=today).slice(0,30);
 const addedToday=words.filter(w=>reviews[w.id]?.added===today).length;
 const fresh=words.filter(w=>!reviews[w.id]).slice(0,Math.max(0,(state.newPerDay||10)-addedToday));
 return {due,fresh};
}
export function correctAnswer(question, value) {return String(value).trim().toLowerCase().replace(/[.!?。！]/g,'') === question.answer.toLowerCase().replace(/[.!?。！]/g,'');}
export function finishLesson(state, id, correct, total, date = new Date()) { const day=localDay(date); const xp=correct*5; return {...state,xp:state.xp+xp, completed: [...new Set([...state.completed, ...(correct/total>=0.6 ? [id] : [])])], days:[...new Set([...state.days,day])],daily:{...state.daily,[day]:(state.daily[day]||0)+xp}}; }
export function recommend(state) { if(state.mistakes.length) return {id:'review',title:'先巩固，再向前',description:`有 ${state.mistakes.length} 道错题等待复习，花几分钟让知识更牢固。`}; const lesson=lessons.find(l=>!state.completed.includes(l.id)) || lessons[0]; return {id:lesson.id,title:lesson.title,description:state.level==='有基础'?'通过情景练习，把熟悉的词变成自然的表达。':'从简单而实用的表达开始，一点点建立英语自信。'}; }

export function validateCourse(course) {
 if(!course || typeof course.title!=='string' || !course.title.trim() || !Array.isArray(course.questions) || course.questions.length<3 || course.questions.length>8) throw Error('Invalid course');
 const questions=course.questions.map(q=>{
  if(!['choice','input','listen'].includes(q.type) || typeof q.prompt!=='string' || typeof q.answer!=='string' || !q.answer.trim() || typeof q.explain!=='string') throw Error('Invalid question');
  if(q.type==='listen' && (typeof q.english!=='string'||!q.english.trim())) throw Error('Missing listening transcript');
  if(q.type!=='input' && (!Array.isArray(q.options)||q.options.length<2||q.options.length>4||q.options.some(o=>typeof o!=='string')||!q.options.includes(q.answer)||new Set(q.options).size!==q.options.length)) throw Error('Invalid options');
  return {type:q.type,prompt:q.prompt.slice(0,300),answer:q.answer.slice(0,300),explain:q.explain.slice(0,1000),...(q.english?{english:String(q.english).slice(0,500)}:{}),...(q.type!=='input'?{options:q.options.map(o=>o.slice(0,300))}:{})};
 });
 return {id:typeof course.id==='string'?course.id.slice(0,80):'generated',title:course.title.slice(0,50),sub:typeof course.sub==='string'?course.sub.slice(0,80):'为你定制的英语练习',tag:'AI 定制',icon:'✧',color:'green',questions};
}
