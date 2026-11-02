/**
 * Import ONLY the 196 additional recipes as private, photo-pending drafts.
 * Dry run by default. Requires the corresponding SQL migration to apply.
 * Does not touch the original 54 published recipes or upload assets.
 *
 * node tool/import_recipe_drafts.mjs
 * node tool/import_recipe_drafts.mjs --apply
 */
import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {validateCatalog} from './import_recipes.mjs';

const draftsPath = new URL('../supabase/catalog/recipe-expansion-drafts.json', import.meta.url);
const originalsPath = new URL('../supabase/catalog/recipes.json', import.meta.url);

export async function importDrafts({apply = false, env = process.env, request = fetch, file = draftsPath,
  originals = originalsPath} = {}) {
  const [manifest, originalManifest] = await Promise.all([
    readFile(file, 'utf8').then(JSON.parse),
    readFile(originals, 'utf8').then(JSON.parse),
  ]);
  if (manifest.schema_version !== 1 || !Array.isArray(manifest.recipes) || manifest.recipes.length !== 196) {
    throw new Error('Expected exactly 196 new recipes in recipe-expansion-drafts.json');
  }
  if (!Array.isArray(originalManifest.recipes) || originalManifest.recipes.length !== 54) {
    throw new Error('Original 54-recipe reference is missing; aborting to protect existing data');
  }
  const originalIds = new Set(originalManifest.recipes.map(recipe => recipe.id));
  if (new Set(manifest.recipes.map(recipe => recipe.id)).size !== 196 ||
      manifest.recipes.some(recipe => originalIds.has(recipe.id))) {
    throw new Error('Duplicate IDs or overlap with the original 54 recipes');
  }
  for (const recipe of manifest.recipes) {
    if (recipe.photo !== null || recipe.photo_status !== 'pending_generation' ||
        recipe.source !== 'miga-editorial-2026-11' ||
        recipe.estimated_cost?.currency !== 'DOP' ||
        recipe.estimated_cost?.estimated !== true ||
        !Number.isSafeInteger(recipe.estimated_cost?.total_cents) ||
        !Number.isSafeInteger(recipe.estimated_cost?.per_serving_cents) ||
        recipe.estimated_cost.total_cents <= 0 ||
        recipe.estimated_cost.per_serving_cents <= 0) {
      throw new Error(`Unexpected photo or pricing metadata in ${recipe.id}`);
    }
  }
  // Validate every field other than the legitimately absent draft photograph.
  // This synthetic object exists only in RAM for validation, never in the upload.
  const validationOnly = manifest.recipes.map(recipe => ({
    ...recipe, photo: {path:'validation-only.webp', width:1, height:1},
  }));
  validateCatalog({schema_version:1, recipes:validationOnly});

  const result = {newRecipes:196, existingPreserved:54, status:'draft', photosUploaded:0,
    pricesEstimatedDOP:true, applied:false};
  if (!apply) return result;

  // Read only the public project URL from the app config. The private admin key is never read from the app.
  const appConfig = await readFile(new URL('../supabase.env.json', import.meta.url), 'utf8')
    .then(JSON.parse).catch(() => ({}));
  const url = (env.SUPABASE_URL || appConfig.SUPABASE_URL)?.trim().replace(/\/$/, '');
  const key = env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!url || !key) throw new Error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in this terminal (never in Flutter)');
  const parsed = new URL(url);
  if (parsed.protocol !== 'https:' && !(parsed.protocol === 'http:' && ['localhost','127.0.0.1'].includes(parsed.hostname))) {
    throw new Error('Supabase URL must use HTTPS');
  }
  // All 196 draft inserts are one PostgREST transaction; duplicates are ignored,
  // so rerunning is safe and existing records (including originals) are unchanged.
  const rows = manifest.recipes.map(recipe => ({id:recipe.id, data:recipe, status:'draft'}));
  const response = await request(`${url}/rest/v1/miga_recipes?on_conflict=id`, {
    method:'POST',
    headers:{apikey:key,Authorization:`Bearer ${key}`,'Content-Type':'application/json',
      Prefer:'resolution=ignore-duplicates,return=minimal'},
    body:JSON.stringify(rows),
  });
  if (!response.ok) {
    const detail = (await response.text().catch(()=>'')).slice(0,450).replaceAll(key,'[redacted]');
    throw new Error(`Supabase rejected draft import (${response.status}). ${detail}\nCheck that the photo-pending drafts SQL migration was applied first.`);
  }
  return {...result, applied:true};
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const args = process.argv.slice(2);
  if (args.some(arg => arg !== '--apply') || args.length > 1) {
    console.error('Usage: node tool/import_recipe_drafts.mjs [--apply]');
    process.exitCode = 1;
  } else {
    try { console.log(JSON.stringify(await importDrafts({apply:args.includes('--apply')}),null,2)); }
    catch(e) { console.error(e.message); process.exitCode=1; }
  }
}
