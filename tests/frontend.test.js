import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
test('inline frontend JavaScript parses and required form targets exist',async()=>{
 const html=await readFile(new URL('../frontend/index.html',import.meta.url),'utf8');
 const script=html.match(/<script>([\s\S]*?)<\/script>/)[1];
 assert.doesNotThrow(()=>new vm.Script(script));
 const ids=[...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]);
 assert.equal(ids.length,new Set(ids).size,'Element IDs must be unique');
 for(const target of ['player','content','purchase-form','limits-form','purchase-dialog','limits-dialog'])assert.ok(ids.includes(target));
});
