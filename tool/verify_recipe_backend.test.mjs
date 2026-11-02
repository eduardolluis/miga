import test from 'node:test';
import assert from 'node:assert/strict';
import { verifyRecipeBackend } from './verify_recipe_backend.mjs';
const env = {url:'https://miga.example.com',key:'sb_publishable_test'};

test('Verifies every published photo, no service role needed', async () => {
  const urls = [];
  const request = async (url, options) => {
    urls.push([url, options.method]);
    if (url.endsWith('miga_recipe_snapshot')) return Response.json([
      {id:'a', photo:{path:'recipes/a-123.jpg'}},
      {id:'b', photo:{path:'recipes/b-456.jpg'}},
    ]);
    return new Response(null,{status:200});
  };
  const result = await verifyRecipeBackend({...env,request});
  assert.deepEqual(result,{published:2,checked:2,failures:[]});
  assert.equal(urls.length,3);
  assert.ok(urls.every(([url])=>url.startsWith(env.url)));
});

test('Missing photo returns a visible failure without silently inventing assets', async () => {
  const request = async (url) => url.endsWith('miga_recipe_snapshot') ?
    Response.json([{id:'missing',photo:{path:'image.jpg'}}]) :
    new Response(null,{status:404});
  const result = await verifyRecipeBackend({...env,request});
  assert.equal(result.published,1);
  assert.equal(result.failures[0].status,'HTTP 404');
});

test('Missing database migration is diagnosed instead of reporting no photos', async () => {
  await assert.rejects(verifyRecipeBackend({...env,request:async()=>new Response(null,{status:404})}),/migration/);
});
