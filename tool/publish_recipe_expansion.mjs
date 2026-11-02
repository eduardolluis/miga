/** Publish the 196 additions and verify the public app catalog. Dry run by default.
 * source /private/tmp/miga-supabase-admin.env
 * node tool/publish_recipe_expansion.mjs --apply
 */
import {readFile, writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {isDeepStrictEqual} from 'node:util';
import {finalize} from './finalize_recipe_expansion.mjs';
import {importCatalog} from './import_recipes.mjs';
import {verifyRecipeBackend} from './verify_recipe_backend.mjs';

const readJson = async path => JSON.parse(await readFile(path, 'utf8'));

export async function publishExpansion({apply = false} = {}) {
  const root = resolve('supabase/catalog/photos');
  const output = resolve('supabase/catalog/recipes-250-import-ready.json');
  const additionsFile = resolve('supabase/catalog/recipes-196-import-ready.json');
  await finalize({emit:true, output});
  const [full, drafts, originals, config] = await Promise.all([
    readJson(output), readJson('supabase/catalog/recipe-expansion-drafts.json'),
    readJson('supabase/catalog/recipes.json'), readJson('supabase.env.json'),
  ]);
  const originalIds = new Set(originals.recipes.map(r => r.id));
  const addedIds = new Set(drafts.recipes.map(r => r.id));
  if (originalIds.size !== 54 || addedIds.size !== 196 ||
      [...addedIds].some(id => originalIds.has(id))) {
    throw new Error('Expected 196 unique additions separate from the original 54');
  }
  const additions = full.recipes.filter(r => addedIds.has(r.id));
  if (additions.length !== 196) throw new Error('Missing additions in the finalized catalog');
  await writeFile(additionsFile, JSON.stringify({schema_version:1, recipes:additions},null,2)+'\n');
  const validation = await importCatalog({file:additionsFile, photosDir:root, status:'published'});
  if (!apply) return {...validation, originalRecipesPreserved:54, manifest:additionsFile};

  const url = config.SUPABASE_URL?.replace(/\/$/,'');
  if (process.env.SUPABASE_URL && process.env.SUPABASE_URL.replace(/\/$/,'') !== url) {
    throw new Error('Operator project does not match the app project');
  }
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!url || !key) throw new Error('Load SUPABASE_SERVICE_ROLE_KEY in the operator terminal');
  const publicHeaders = {apikey:config.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json'};
  const snapshot = async () => {
    const res = await fetch(url+'/rest/v1/rpc/miga_recipe_snapshot', {
      method:'POST', headers:publicHeaders, body:'{}', signal:AbortSignal.timeout(20000),
    });
    if (!res.ok) throw new Error('Public catalog returned HTTP '+res.status);
    const rows = await res.json();
    if (!Array.isArray(rows)) throw new Error('Public catalog is not an array');
    return new Map(rows.map(r => [r.id,r]));
  };
  const before = await snapshot();
  for (const id of originalIds) {
    if (!before.has(id)) throw new Error('Original recipe missing before publication: '+id);
  }
  const result = await importCatalog({file:additionsFile, photosDir:root, status:'published',
    apply:true, env:{SUPABASE_URL:url, SUPABASE_SERVICE_ROLE_KEY:key}});
  const after = await snapshot();
  for (const id of originalIds) {
    if (!isDeepStrictEqual(before.get(id),after.get(id))) {
      throw new Error('Original recipe changed during publication: '+id);
    }
  }
  for (const recipe of additions) {
    const bytes = await readFile(resolve(root,recipe.photo.path));
    const hash = createHash('sha256').update(bytes).digest('hex').slice(0,16);
    const expected = structuredClone(recipe);
    expected.photo.path = expected.photo.path.replace(/(\.[^.]+)$/, '-'+hash+'$1');
    if (!isDeepStrictEqual(expected,after.get(recipe.id))) {
      throw new Error('Published recipe does not match its import: '+recipe.id);
    }
  }
  const orderedIds = [...after.keys()];
  const searchedIds = [];
  for (let offset = 0; offset < orderedIds.length; offset += 100) {
    const res = await fetch(url+'/rest/v1/rpc/miga_search_recipes', {
      method:'POST', headers:publicHeaders, signal:AbortSignal.timeout(20000),
      body:JSON.stringify({p_ids:orderedIds, p_query:'', p_language:'es',
        p_slot:null, p_offset:offset, p_limit:100}),
    });
    if (!res.ok) throw new Error('Public recipe search returned HTTP '+res.status);
    const page = await res.json();
    const ids = page.recipes?.map(r => r.id);
    if (page.total !== after.size || !isDeepStrictEqual(ids,orderedIds.slice(offset,offset+100))) {
      throw new Error('Public recipe pagination does not match the published catalog');
    }
    searchedIds.push(...ids);
  }
  const photos = await verifyRecipeBackend({url,key:config.SUPABASE_PUBLISHABLE_KEY});
  if (photos.failures.length || photos.checked !== after.size || photos.published !== after.size) {
    throw new Error('Public photo verification failed: '+JSON.stringify(photos));
  }
  const report = {...result, published:after.size, newRecipesVerified:additions.length,
    originalRecipesPreserved:originalIds.size, photosChecked:photos.checked,
    searchRecipesChecked:searchedIds.length,
    verifiedAt:new Date().toISOString()};
  await writeFile('reports/recipe-expansion-publication.json',JSON.stringify(report,null,2)+'\n');
  return report;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const args = process.argv.slice(2);
  try {
    if (args.length > 1 || args.some(a => a !== '--apply')) throw new Error('Usage: node tool/publish_recipe_expansion.mjs [--apply]');
    console.log(JSON.stringify(await publishExpansion({apply:args.includes('--apply')}),null,2));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
