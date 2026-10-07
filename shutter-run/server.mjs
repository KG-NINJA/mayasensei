import http from 'node:http';import {readFile} from 'node:fs/promises';import {fileURLToPath} from 'node:url';import path from 'node:path';import {requestFor,readAnswer} from './decisions.mjs';
const root=path.dirname(fileURLToPath(import.meta.url)),key=process.env.OPENAI_API_KEY,port=Number(process.env.PORT||4310),allowedOrigin=process.env.ALLOWED_ORIGIN||'',recent=[];
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid PORT');
const trustedOrigins = new Set([`http://localhost:${port}`, `http://127.0.0.1:${port}`]);
const trustedHosts = new Set([`localhost:${port}`, `127.0.0.1:${port}`]);
if (allowedOrigin) {
  const url = new URL(allowedOrigin);
  if (!['http:', 'https:'].includes(url.protocol) || url.origin !== allowedOrigin) {
    throw new Error('ALLOWED_ORIGIN must be an exact HTTP(S) origin');
  }
  trustedOrigins.add(allowedOrigin);
}
const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.json':'application/json; charset=utf-8'};
function json(res,status,value){res.writeHead(status,{'Content-Type':'application/json','Cache-Control':'no-store'});res.end(JSON.stringify(value))}
export const server=http.createServer(async(req,res)=>{try{if (!trustedHosts.has(req.headers.host)) return json(res,403,{error:'Host not allowed'});
const origin=req.headers.origin;
if (origin !== undefined && !trustedOrigins.has(origin)) return json(res,403,{error:'Origin not allowed'});
if (origin && origin === allowedOrigin) {
  res.setHeader('Access-Control-Allow-Origin',origin);
  res.setHeader('Vary','Origin');
  res.setHeader('Access-Control-Allow-Methods','GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers','Content-Type');
}
if(req.method==='OPTIONS'){res.writeHead(204);return res.end()}const url=new URL(req.url,'http://localhost');if(url.pathname==='/api/config'&&req.method==='GET')return json(res,200,{available:!!key,model:'gpt-6-luna',provider:'openai_decisions'});if(url.pathname==='/api/decide'&&req.method==='POST'){if(!key)return json(res,503,{error:'OPENAI_API_KEY is not configured'});const now=Date.now();while(recent.length&&recent[0]<now-1000)recent.shift();if(recent.length>=3){res.setHeader('Retry-After','1');return json(res,429,{error:'Decision rate limit: 3 requests/sec'})}recent.push(now);let raw='',size=0;for await(const chunk of req){size+=chunk.length;if(size>16000)return json(res,413,{error:'Request too large'});raw+=chunk}let state,payload;try{state=JSON.parse(raw).state;payload=requestFor(state)}catch{return json(res,400,{error:'Invalid flight state'})}const begin=performance.now();const response=await fetch('https://api.openai.com/v1/decisions',{method:'POST',headers:{'Authorization':`Bearer ${key}`,'Content-Type':'application/json'},body:JSON.stringify(payload),signal:AbortSignal.timeout(1500)});if(!response.ok)return json(res,response.status===429?429:502,{error:`Decisions API returned ${response.status}`});const data=readAnswer(await response.json(),state);return json(res,200,{...data,api_latency_ms:Math.round(performance.now()-begin)})}if(req.method!=='GET'&&req.method!=='HEAD')return json(res,405,{error:'Method not allowed'});const pathname=decodeURIComponent(url.pathname);const filename=path.resolve(root,'.'+(pathname==='/'?'/index.html':pathname));if(!filename.startsWith(root+path.sep))return json(res,403,{error:'Forbidden'});if(!['index.html','style.css','game.mjs','physics.mjs'].includes(path.relative(root,filename)))return json(res,404,{error:'Not found'});const content=await readFile(filename);res.writeHead(200,{'Content-Type':types[path.extname(filename)]||'application/octet-stream','Cache-Control':'no-store'});res.end(req.method==='HEAD'?undefined:content)}catch(error){json(res,502,{error:error.name==='TimeoutError'?'Decisions API timed out':'Request failed'})}});
server.listen(port,'127.0.0.1',()=>console.log(`SHUTTER RUN http://127.0.0.1:${port} — Decisions API ${key?'configured':'not configured (manual available)'}`));
