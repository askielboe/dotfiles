import { test } from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { createInterface } from "node:readline";
import { mkdtemp, writeFile, chmod, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

async function fixture(t) {
  const dir = await mkdtemp(join(tmpdir(), "history-bridge-test-"));
  const fake = join(dir, "codex");
  await writeFile(fake, `#!${process.execPath}
const readline = require('node:readline');
let approval;
const tool = {name:'computer_history_status',inputSchema:{type:'object'},annotations:{readOnlyHint:true}};
function send(m) {process.stdout.write(JSON.stringify(m)+'\\n')}
readline.createInterface({input:process.stdin}).on('line', l => {
 const m=JSON.parse(l);
 if(m.id===undefined)return;
 if(!m.method) {send({id:approval,result:{content:[{type:'text',text:JSON.stringify(m.result)}]}});return;}
 switch(m.method) {
 case 'initialize':send({id:m.id,result:{}});break;
 case 'thread/start':
  if(!m.params.ephemeral || m.params.sandbox!=='read-only')throw Error('Unexpected thread configuration');
  send({id:m.id,result:{thread:{id:'diagnostic'}}});break;
 case 'mcpServerStatus/list':send({id:m.id,result:{data:[{name:'computer-history',tools:{computer_history_status:tool}}]}});break;
 case 'mcpServer/tool/call':
  if(m.params.arguments.fail) {send({id:m.id,error:{code:-1,message:'backend failed'}});break;}
  if(m.params.arguments.crash) {process.exit(7);break;}
  if(m.params.arguments.approval) {
   approval=m.id;
   send({id:99,method:'mcpServer/elicitation/request',params:{threadId:'diagnostic',serverName:'computer-history',mode:'form',message:'Approve?',requestedSchema:{type:'object',properties:{}},_meta:{riskLevel:'high'}}});
   break;
  }
  send({id:m.id,result:{content:[{type:'text',text:JSON.stringify({state:'stopped',meta:m.params._meta})}]}});break;
 }
});
`);
  await chmod(fake, 0o700);
  const child = spawn(process.execPath, [fileURLToPath(new URL("./computer-history-mcp.mjs", import.meta.url)), fake], { stdio: ["pipe", "pipe", "pipe"] });
  const lines = createInterface({ input: child.stdout });
  const queue = [];
  const waiters = [];
  lines.on("line", (line) => {
    const value = JSON.parse(line);
    if (waiters.length) waiters.shift()(value);
    else queue.push(value);
  });
  t.after(async () => {
    child.kill();
    lines.close();
    await rm(dir, { recursive: true, force: true });
  });
  const send = (message) => child.stdin.write(`${JSON.stringify({jsonrpc:"2.0",...message})}\n`);
  const next = () => queue.length ? Promise.resolve(queue.shift()) : new Promise((resolve) => waiters.push(resolve));
  send({id:1,method:"initialize",params:{protocolVersion:"2024-11-05",capabilities:{elicitation:{form:{}}}}});
  const initialized = await next();
  assert.equal(initialized.result.protocolVersion, "2024-11-05");
  return { child, send, next };
}

test("discovers native tools and forwards status and metadata", {timeout:10000}, async (t) => {
  const {send,next}=await fixture(t);
  send({id:2,method:"tools/list",params:{}});
  assert.equal((await next()).result.tools[0].name,"computer_history_status");
  send({id:3,method:"tools/call",params:{name:"computer_history_status",_meta:{trace:"test"}}});
  assert.deepEqual(JSON.parse((await next()).result.content[0].text),{state:"stopped",meta:{trace:"test"}});
});

test("forwards approval requests and preserves declines", {timeout:10000}, async (t) => {
  const {send,next}=await fixture(t);
  send({id:2,method:"tools/call",params:{name:"computer_history_status",arguments:{approval:true}}});
  const approval=await next();
  assert.equal(approval.method,"elicitation/create");
  assert.equal(approval.params._meta.riskLevel,"high");
  assert.equal(approval.params.threadId,undefined);
  send({id:approval.id,result:{action:"decline"}});
  assert.deepEqual(JSON.parse((await next()).result.content[0].text),{action:"decline"});
});

test("rejects unknown tools and propagates backend errors", {timeout:10000}, async (t) => {
  const {send,next}=await fixture(t);
  send({id:2,method:"tools/call",params:{name:"unrelated_tool"}});
  assert.match((await next()).error.message,/Unknown/);
  send({id:3,method:"tools/call",params:{name:"computer_history_status",arguments:{fail:true}}});
  assert.equal((await next()).error.message,"backend failed");
});

test("backend exit rejects pending calls", {timeout:10000}, async (t) => {
  const {send,next}=await fixture(t);
  send({id:2,method:"tools/call",params:{name:"computer_history_status",arguments:{crash:true}}});
  assert.match((await next()).error.message,/exited/);
});
