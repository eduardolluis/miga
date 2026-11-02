import { readFile, stat } from 'node:fs/promises';
import { resolve, extname, basename, dirname, sep } from 'node:path';
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';

const ingredientUnits = JSON.parse(await readFile(new URL('../supabase/catalog/ingredients.json', import.meta.url), 'utf8'));
const integer = (n, min, max) => Number.isSafeInteger(n) && n >= min && n <= max;
const text = (s) => typeof s === 'string' && s.trim().length > 0;
const fail = (message) => { throw new Error(message); };

export function imageDimensions(bytes) {
  if (bytes.length >= 24 && bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) {
    return [bytes.readUInt32BE(16), bytes.readUInt32BE(20)];
  }
  if (bytes.length >= 4 && bytes[0] === 255 && bytes[1] === 216) {
    let offset = 2;
    while (offset + 9 < bytes.length) {
      if (bytes[offset++] !== 255) break;
      while (bytes[offset] === 255) offset++;
      const marker = bytes[offset++];
      if (marker === 217 || marker === 218) break;
      if (marker === 1 || (marker >= 208 && marker <= 215)) continue;
      const length = bytes.readUInt16BE(offset);
      if (length < 2 || offset + length > bytes.length) break;
      if ([192,193,194,195,197,198,199,201,202,203,205,206,207].includes(marker)) {
        return [bytes.readUInt16BE(offset + 5), bytes.readUInt16BE(offset + 3)];
      }
      offset += length;
    }
  }
  if (bytes.length >= 30 && bytes.toString('ascii',0,4) === 'RIFF' && bytes.toString('ascii',8,12) === 'WEBP') {
    const type = bytes.toString('ascii',12,16);
    if (type === 'VP8X') return [1 + bytes.readUIntLE(24,3), 1 + bytes.readUIntLE(27,3)];
    if (type === 'VP8 ') return [bytes.readUInt16LE(26) & 16383, bytes.readUInt16LE(28) & 16383];
    if (type === 'VP8L' && bytes[20] === 47) {
      const value = bytes.readUInt32LE(21);
      return [(value & 16383) + 1, ((value >>> 14) & 16383) + 1];
    }
  }
  fail('Unsupported or corrupt photo');
}

export function validateCatalog(catalog) {
  if (catalog?.schema_version !== 1 || !Array.isArray(catalog.recipes) || !catalog.recipes.length) fail('Expected schema_version 1 and a nonempty recipes array');
  const ids = new Set();
  for (const r of catalog.recipes) {
    const at = `Recipe ${r?.id ?? '(missing ID)'}`;
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(r.id ?? '') || r.id.length > 100 || ids.has(r.id)) fail(`${at}: invalid or duplicate ID`);
    ids.add(r.id);
    if (!['breakfast','lunch','dinner'].includes(r.slot) || !integer(r.minutes, 1, 1440) ||
        !integer(r.servings, 1, 24) || !integer(r.sort_order, 0, 2147483647) || !text(r.source)) fail(`${at}: invalid metadata`);
    const photo = r.photo;
    if (photo?.thumbnail_path != null &&
        (typeof photo.thumbnail_path !== 'string' ||
         !/^[a-zA-Z0-9_/-]+\.(jpg|jpeg|webp|png)$/.test(photo.thumbnail_path) ||
         photo.thumbnail_path.startsWith('/') || photo.thumbnail_path.includes('..') ||
         !integer(photo.thumbnail_width,1,10000) || !integer(photo.thumbnail_height,1,10000))) {
      fail('Invalid photo thumbnail for ' + r.id);
    }
    if (!photo || !/^[a-zA-Z0-9_/-]+\.(jpg|jpeg|webp|png)$/.test(photo.path ?? '') || photo.path.startsWith('/') || photo.path.includes('..') ||
        !integer(photo.width,1,10000) || !integer(photo.height,1,10000)) fail(`${at}: invalid photo`);
    if (!Array.isArray(r.amounts) || !r.amounts.length || r.amounts.length > 100) fail(`${at}: missing ingredient quantities`);
    const ingredients = new Set();
    for (const a of r.amounts) {
      if (!Object.hasOwn(ingredientUnits,a.ingredient) || ingredients.has(a.ingredient) ||
          !['grams','milliliters','pieces'].includes(a.unit) || !Number.isFinite(a.amount) || a.amount < 0.000001 || a.amount > 1000000 ||
          (a.grams_per_piece != null && (!Number.isFinite(a.grams_per_piece) || a.grams_per_piece <= 0))) fail(`${at}: invalid, unsupported or duplicate ingredient`);
      ingredients.add(a.ingredient);
    }
    for (const language of ['es','en']) {
      const c = r[language];
      if (!c || !text(c.title) || !text(c.description) || !Array.isArray(c.ingredients) || !c.ingredients.length ||
          !c.ingredients.every(text) || !Array.isArray(c.steps) || !c.steps.length || !c.steps.every(text)) fail(`${at}: incomplete ${language} translation`);
    }
    if (r.nutrition != null) {
      if (typeof r.nutrition.estimated !== 'boolean' || !['calories','protein_grams','carbs_grams'].every((k) => integer(r.nutrition[k],0,100000)) ||
          (r.nutrition.fat_grams != null && !integer(r.nutrition.fat_grams,0,100000))) fail(`${at}: invalid nutrition`);
    }
    if (!Array.isArray(r.tags) || !r.tags.every(text) || JSON.stringify(r).length > 190000) fail(`${at}: invalid tags or oversized content`);
  }
  return catalog.recipes;
}

export async function importCatalog({file, photosDir, status = 'draft', apply = false,
  env = process.env, request = fetch}) {
  if (!['draft','review','published','archived'].includes(status)) fail('Unknown publication status');
  const recipes = validateCatalog(JSON.parse(await readFile(file, 'utf8')));
  const root = resolve(photosDir);
  const files = new Map();
  const rows = [];
  for (const original of recipes) {
    const recipe = structuredClone(original);
    const path = resolve(root, recipe.photo.path);
    if (!path.startsWith(root + sep)) fail('Photo escapes the source directory');
    const info = await stat(path);
    if (!info.isFile() || info.size > 8388608 || info.size === 0) fail(`Invalid photo for ${recipe.id}`);
    const bytes = await readFile(path);
    const [width, height] = imageDimensions(bytes);
    if (width !== recipe.photo.width || height !== recipe.photo.height) fail(`Photo dimensions do not match ${recipe.id}`);
    const hash = createHash('sha256').update(bytes).digest('hex').slice(0,16);
    const extension = extname(path).toLowerCase();
    const folder = dirname(recipe.photo.path);
    const target = `${folder === '.' ? '' : folder + '/'}${basename(path,extension)}-${hash}${extension}`;
    files.set(target, {bytes, type: extension === '.png' ? 'image/png' : extension === '.webp' ? 'image/webp' : 'image/jpeg'});
    recipe.photo.path = target;
    if (recipe.photo.thumbnail_path != null) {
      const thumbnailPath = resolve(root,recipe.photo.thumbnail_path);
      if (!thumbnailPath.startsWith(root + sep)) fail('Photo thumbnail escapes the source directory');
      const thumbnailInfo = await stat(thumbnailPath);
      if (!thumbnailInfo.isFile() || thumbnailInfo.size > 8388608 || thumbnailInfo.size === 0) fail('Invalid thumbnail for ' + recipe.id);
      const thumbnailBytes = await readFile(thumbnailPath);
      const [thumbnailWidth,thumbnailHeight] = imageDimensions(thumbnailBytes);
      if (thumbnailWidth !== recipe.photo.thumbnail_width || thumbnailHeight !== recipe.photo.thumbnail_height) fail('Photo thumbnail dimensions do not match ' + recipe.id);
      const thumbnailHash = createHash('sha256').update(thumbnailBytes).digest('hex').slice(0,16);
      const thumbnailExtension = extname(thumbnailPath).toLowerCase();
      const thumbnailTarget = dirname(recipe.photo.thumbnail_path) + '/' +
        basename(thumbnailPath,thumbnailExtension) + '-' + thumbnailHash + thumbnailExtension;
      files.set(thumbnailTarget,{bytes:thumbnailBytes,type:thumbnailExtension === '.png' ? 'image/png' : thumbnailExtension === '.webp' ? 'image/webp' : 'image/jpeg'});
      recipe.photo.thumbnail_path = thumbnailTarget;
    }
    rows.push({id: recipe.id, data: recipe, status});
  }
  if (!apply) return {recipes: rows.length, photos: files.size, status, applied: false};
  const url = env.SUPABASE_URL?.replace(/\/$/,'');
  const key = env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) fail('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in the operator environment');
  const parsed = new URL(url);
  if (parsed.protocol !== 'https:' && !(parsed.protocol === 'http:' && ['127.0.0.1','localhost'].includes(parsed.hostname))) fail('Supabase requires HTTPS');
  const headers = {apikey:key, Authorization:`Bearer ${key}`};
  // Immutable hashed filenames prevent stale photos and make retries safe.
  const uploads = [...files];
  for (let offset = 0; offset < uploads.length; offset += 8) {
    await Promise.all(uploads.slice(offset, offset + 8).map(async ([path, photo]) => {
      const response = await request(`${url}/storage/v1/object/recipe-photos/${path}`, {
        method:'POST', headers:{...headers,'Content-Type':photo.type,'Cache-Control':'max-age=31536000','x-upsert':'false'}, body:photo.bytes,
        signal:AbortSignal.timeout(30000),
      });
      if (!response.ok && response.status !== 409) {
        const problem = await response.json().catch(() => ({}));
        const duplicate = response.status === 400 &&
          (String(problem.statusCode) === '409' || problem.error === 'Duplicate');
        if (!duplicate) fail(`Photo upload failed (${response.status}); recipe metadata was not written`);
      }
    }));
    if (uploads.length > 8) console.log(`Uploaded photos ${Math.min(offset + 8, uploads.length)}/${uploads.length}`);
  }
  // One upsert request is one database transaction. created_at/published_at are
  // managed by the DB, so rerunning an import preserves first-publication dates.
  const response = await request(`${url}/rest/v1/miga_recipes?on_conflict=id`, {
    method:'POST', headers:{...headers,'Content-Type':'application/json',Prefer:'resolution=merge-duplicates,return=minimal'}, body:JSON.stringify(rows),
  });
  if (!response.ok) fail(`Catalog upsert failed (${response.status}); existing rows were not partially changed`);
  return {recipes:rows.length, photos:files.size, status, applied:true};
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    const args = process.argv.slice(2);
    const option = (key, fallback) => {
      const index = args.indexOf(key);
      if (index < 0) return fallback;
      if (!args[index + 1] || args[index + 1].startsWith('--')) fail(`Missing value for ${key}`);
      return args[index + 1];
    };
    const known = new Set(['--file','--photos-dir','--status','--apply']);
    for (let i=0;i<args.length;i++) { if (!known.has(args[i])) fail(`Unknown option ${args[i]}`); if (args[i] !== '--apply') i++; }
    const result = await importCatalog({file:option('--file','supabase/catalog/recipes.json'),
      photosDir:option('--photos-dir','supabase/catalog/photos'),status:option('--status','draft'),
      apply:args.includes('--apply')});
    console.log(JSON.stringify(result));
  } catch (error) { console.error(error.message); process.exitCode=1; }
}
