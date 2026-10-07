import assert from 'node:assert/strict';
import http from 'node:http';
import {once} from 'node:events';
import {spawnSync} from 'node:child_process';
import {Run} from '../physics.mjs';

// Isolated test process: no real credentials and no upstream network calls.
const reservation = http.createServer();
reservation.listen(0, '127.0.0.1');
await once(reservation, 'listening');
const port = reservation.address().port;
await new Promise(resolve => reservation.close(resolve));
process.env.PORT = String(port);
process.env.OPENAI_API_KEY = 'test-only-dummy-key';
process.env.ALLOWED_ORIGIN = 'https://play.example';
let upstreamCalls = 0;
globalThis.fetch = async (_url, options) => {
  upstreamCalls++;
  const payload = JSON.parse(options.body);
  return {ok:true, json:async()=>({answers:payload.questions.map(q=>({
    type:'choice', name:q.name, choice:'lane_3', probabilities:[]
  }))})};
};
const {server} = await import('../server.mjs');
if (!server.listening) await once(server, 'listening');
const localHost = `127.0.0.1:${port}`;
const localOrigin = `http://${localHost}`;
const evilHost = `evil.example:${port}`;
const evilOrigin = `http://${evilHost}`;
const body = JSON.stringify({state:new Run({mode:'api'}).observation()});
function request(method, path, host, origin, extra={}) {
  return new Promise((resolve,reject)=>{
    const headers = {Host:host, ...extra};
    if (origin !== undefined) headers.Origin = origin;
    if (method === 'POST') headers['Content-Type']='application/json';
    const req=http.request({hostname:'127.0.0.1',port,method,path,headers},res=>{
      res.resume();res.on('end',()=>resolve({status:res.statusCode,headers:res.headers}));
    });
    req.on('error',reject);req.end(method==='POST'?body:undefined);
  });
}
let rejected=0;
try {
  const attacks=[
    [evilHost,evilOrigin], [evilHost,undefined], [localHost,evilOrigin],
    [evilHost,localOrigin], [evilHost,'https://play.example'],
    [localHost,'null'], [localHost,`http://127.0.0.1:${port+1}`],
    [localHost,'https://play.example.evil.test'],
    [localHost,'https://play.example/'],
  ];
  for(const [host,origin] of attacks) for(const [method,path] of [
    ['POST','/api/decide'],['GET','/api/config'],['OPTIONS','/api/decide'],['GET','/']
  ]) {
    const result=await request(method,path,host,origin,{'X-Forwarded-Host':localHost,'X-Forwarded-Proto':'http'});
    assert.equal(result.status,403,`${method} ${host} / ${origin}`);
    assert.equal(result.headers['access-control-allow-origin'],undefined);
    assert.equal(upstreamCalls,0);rejected++;
  }
  for(const origin of [undefined,localOrigin,`http://localhost:${port}`,'https://play.example']) {
    const result=await request('GET','/api/config',localHost,origin);
    assert.equal(result.status,200);
    assert.equal(result.headers['access-control-allow-origin'],origin==='https://play.example'?origin:undefined);
  }
  assert.equal((await request('GET','/',`localhost:${port}`,`http://localhost:${port}`)).status,200);
  const preflight=await request('OPTIONS','/api/decide',localHost,'https://play.example');
  assert.equal(preflight.status,204);assert.equal(preflight.headers['access-control-allow-origin'],'https://play.example');
  for(const origin of [localOrigin,'https://play.example']) assert.equal((await request('POST','/api/decide',localHost,origin)).status,200);
  assert.equal(upstreamCalls,2);
  for(const origin of ['null','https://play.example/','https://user:pass@play.example','https://play.example/path']) {
    const child=spawnSync(process.execPath,['shutter-run/server.mjs'],{
      cwd:new URL('../../',import.meta.url),env:{...process.env,ALLOWED_ORIGIN:origin},timeout:3000,encoding:'utf8'
    });
    assert.equal(child.error,undefined);assert.notEqual(child.status,0);assert.match(child.stderr,/Error/);
  }
  console.log(JSON.stringify({rejected_requests:rejected,rejected_upstream_calls:0,allowed_mock_calls:upstreamCalls,live_api_tested:false}));
} finally { await new Promise(resolve=>server.close(resolve)); }
