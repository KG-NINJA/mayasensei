export const GATE_COUNT=52;
export const W=480,H=760,SHIP_Y=605,RADIUS=11,SHIP_SPEED=860,LANES=[86,163,240,317,394];
export const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
export function course(seed=1024,count=GATE_COUNT){let n=seed>>>0;const rng=()=>{n=(Math.imul(n,1664525)+1013904223)>>>0;return n/4294967296};let last=2;return Array.from({length:count},(_,i)=>{let lane=Math.floor(rng()*5);if(lane===last)lane=(lane+1+Math.floor(rng()*3))%5;last=lane;return {id:i+1,distance:760+i*530,lane,center:LANES[lane],thickness:26,passed:false}})}
export function gapWidth(remaining){const t=clamp(1-remaining/700,0,1);return 190-102*t*t*(3-2*t)}
export class Run{
 constructor({seed=1024,difficulty='rapid',mode='manual'}={}){this.seed=seed;this.difficulty=difficulty;this.mode=mode;this.gates=course(seed);this.x=W/2;this.time=0;this.distance=0;this.speed=difficulty==='rapid'?210:160;this.acceleration=difficulty==='rapid'?36:16;this.maxSpeed=difficulty==='rapid'?1500:1100;this.passed=0;this.status='running';this.clearance=Infinity;this.target=W/2;this.lastHit=null}
 step(dt,input=0){if(this.status!=='running')return;dt=clamp(dt,0,.1);const d0=this.distance,x0=this.x;this.time+=dt;this.speed=Math.min(this.maxSpeed,(this.difficulty==='rapid'?210:160)+this.acceleration*this.time);this.distance+=this.speed*dt;const move=this.mode==='manual'?input*SHIP_SPEED*dt:clamp(this.target-this.x,-SHIP_SPEED*dt,SHIP_SPEED*dt);this.x=clamp(this.x+move,30,W-30);
  for(const g of this.gates){const half=g.thickness/2+RADIUS,start=g.distance-half,end=g.distance+half;if(this.distance>=start&&d0<=end){const denom=this.distance-d0;const a=clamp((start-d0)/denom,0,1),b=clamp((end-d0)/denom,0,1);for(const t of [a,b]){const x=x0+(this.x-x0)*t,remaining=g.distance-(d0+denom*t),margin=gapWidth(remaining)/2-RADIUS-Math.abs(x-g.center);this.clearance=Math.min(this.clearance,margin);if(margin<0){this.status='crashed';this.lastHit=g.id;return}}}if(!g.passed&&this.distance>end){g.passed=true;this.passed++}}
  if(this.distance>this.gates.at(-1).distance+350)this.status='cleared';
 }
 observation(){return {ship:{x:Math.round(this.x),radius:RADIUS,lateral_speed:SHIP_SPEED},scroll:{speed:Math.round(this.speed),acceleration:this.acceleration,max_speed:this.maxSpeed},lanes:LANES.map((x,i)=>({value:`lane_${i+1}`,x})),shutters:this.gates.filter(g=>g.distance-this.distance>=-(g.thickness/2+RADIUS)).slice(0,4).map(g=>({id:g.id,distance_to_ship:Math.round(g.distance-this.distance),time_to_cross:+((g.distance-this.distance)/this.speed).toFixed(3),gap_center:g.center,gap_width_at_cross:88,thickness:g.thickness})),seed:this.seed}}
 // Explicitly local reference controller, never used as an API fallback.
 referenceTarget(){return this.observation().shutters[0]?.gap_center??this.x}
}
