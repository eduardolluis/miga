/**
 * Turn the 250-item editorial staging file into an importer-compatible manifest
 * ONLY after every new recipe has a real image file. This never invents assets.
 *
 * node tool/finalize_recipe_expansion.mjs                 # status only
 * node tool/finalize_recipe_expansion.mjs --emit          # requires 196 images
 * node tool/import_recipes.mjs --file supabase/catalog/recipes-250-import-ready.json --photos-dir supabase/catalog/photos --status review
 */
import { readFile, stat, writeFile } from 'node:fs/promises';
import { join, resolve, relative } from 'node:path';
import { pathToFileURL } from 'node:url';
import { imageDimensions, validateCatalog } from './import_recipes.mjs';

const catalogPath = resolve('supabase/catalog/recipes-250-staging.json');
const photoRoot = resolve('supabase/catalog/photos');
const outputPath = resolve('supabase/catalog/recipes-250-import-ready.json');
const exts = ['webp','jpg','jpeg','png'];

export async function finalize({ catalog = catalogPath, photosDir = photoRoot,
  output = outputPath, emit = false } = {}) {
  const staging = JSON.parse(await readFile(catalog, 'utf8'));
  if (staging.schema_version !== 1 || staging.recipes?.length !== 250) {
    throw new Error('Expected editorial staging manifest of 250 recipes');
  }
  const ready = [];
  const missing = [];
  const ids = new Set();
  for (const raw of staging.recipes) {
    if (ids.has(raw.id)) throw new Error(`Duplicate id: ${raw.id}`);
    ids.add(raw.id);
    const r = structuredClone(raw);
    if (!r.photo) {
      const found = [];
      for (const ext of exts) {
        const path = join(photosDir, 'new', `${r.id}.${ext}`);
        try { if ((await stat(path)).isFile()) found.push(path); } catch (e) { if (e.code !== 'ENOENT') throw e; }
      }
      if (!found.length) {missing.push(r.id); continue;}
      if (found.length !== 1) throw new Error(`Multiple candidate images for ${r.id}`);
      const bytes = await readFile(found[0]);
      if (bytes.byteLength > 8 * 1024 * 1024) throw new Error(`Image too large for ${r.id}`);
      const [width, height] = imageDimensions(bytes);
      r.photo = {path:relative(photosDir,found[0]).replaceAll('\\','/'), width, height};
      delete r.photo_status;
      r.tags = (r.tags ?? []).filter(t => t !== 'photo-pending');
    }
    ready.push(r);
  }
  const status = {total:staging.recipes.length, photosReady:ready.length, missingCount:missing.length,
    missingSample:missing.slice(0,12), canPublish:missing.length===0, applied:false};
  if (emit) {
    if (missing.length) throw new Error(`${missing.length} photos missing. No import manifest written. First examples: ${missing.slice(0,5).join(', ')}`);
    validateCatalog({schema_version:1, recipes:ready});
    await writeFile(output,JSON.stringify({schema_version:1, recipes:ready},null,2)+'\n');
    status.manifest=output;
  }
  return status;
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    if (process.argv.slice(2).some(a=>a!=='--emit')) throw new Error('Only option: --emit');
    console.log(JSON.stringify(await finalize({emit:process.argv.includes('--emit')}),null,2));
  } catch(e) {console.error(e.message);process.exitCode=1;}
}
