import assert from 'node:assert/strict';
import {createWarning} from '../voice.mjs';
const spoken=[];let cancelled=0;
class Utterance {constructor(text){this.text=text}}
const synth={speaking:false,pending:false,cancel(){cancelled++},speak(u){spoken.push(u)},getVoices(){return [{lang:'en-US',name:'English'}]}};
const warning=createWarning(synth,Utterance);
warning.arm();assert.equal(spoken[0].volume,0);
const run={status:'running',passed:25,time:15};warning.tick(run);assert.equal(spoken.length,1);
run.passed=26;warning.tick(run);assert.equal(spoken[1].text,'danger, danger');assert.equal(spoken[1].lang,'en-US');
run.time=17;warning.tick(run);assert.equal(spoken.length,2);
run.time=18;synth.speaking=true;warning.tick(run);assert.equal(spoken.length,2);
synth.speaking=false;warning.tick(run);assert.equal(spoken.length,3);
warning.setEnabled(false);run.time=25;warning.tick(run);assert.equal(spoken.length,3);
warning.setEnabled(true);run.status='crashed';warning.tick(run);assert.equal(spoken.length,4);
warning.stop();assert.ok(cancelled>=4);
const unsupported=createWarning(undefined,undefined);unsupported.arm();unsupported.tick(run);unsupported.stop();assert.equal(unsupported.supported,false);
console.log('TTS warning threshold, cadence, queue, mute, termination and unsupported browser checks passed');
