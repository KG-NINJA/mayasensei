import assert from 'node:assert/strict';import {Run,course,W,LANES} from '../physics.mjs';import {requestFor,readAnswer,validateState} from '../decisions.mjs';
let checks=0;const check=(condition)=>{assert.ok(condition);checks++};
check(JSON.stringify(course(1024))===JSON.stringify(course(1024)));check(JSON.stringify(course(1024))!==JSON.stringify(course(1025)));
for(const difficulty of ['normal','rapid'])for(let seed=1;seed<=40;seed++){const run=new Run({seed,difficulty,mode:'reference'});let max=0;while(run.status==='running'&&run.time<100){run.target=run.referenceTarget();run.step(1/120);check(run.speed>=max);max=run.speed}check(run.status==='cleared');check(run.passed===52);check(run.clearance>=0);if(difficulty==='rapid')check(run.speed>1000)}
const idle=new Run();for(let i=0;i<2000&&idle.status==='running';i++)idle.step(1/120);check(idle.status==='crashed');check(idle.passed<52);
const swept=new Run();swept.distance=course()[0].distance-30;swept.x=30;swept.time=20;swept.step(.1);check(swept.status==='crashed');
const run=new Run({mode:'api'}),state=run.observation(),payload=requestFor(state);check(payload.model==='gpt-6-luna');check(payload.questions.length===3);check(payload.questions.every(q=>q.type==='choice'&&q.choices.length===5));
const fake={answers:state.shutters.slice(0,3).map(g=>({type:'choice',name:`gate_${g.id}`,choice:`lane_${LANES.indexOf(g.gap_center)+1}`,probabilities:[{value:`lane_${LANES.indexOf(g.gap_center)+1}`,probability:1}]}))};const parsed=readAnswer(fake,state);check(parsed.plans.length===3);check(parsed.plans.every((p,i)=>p.gate_id===state.shutters[i].id));assert.throws(()=>readAnswer({answers:[]},state));checks++;assert.throws(()=>validateState({ship:{x:Infinity}}));checks++;check(!JSON.stringify(payload).includes('safe_lane'));


const late=structuredClone(state);late.shutters[0].id=52;check(validateState(late).shutters[0].id===52);late.shutters[0].id=53;assert.throws(()=>validateState(late));

console.log(JSON.stringify({checks,failures:[],reference_controller_seeds:80,live_api_tested:false}));
