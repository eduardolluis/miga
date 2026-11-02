import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const assertNonEmpty = (value, name) => {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`Missing ${name}`);
  }
  return value;
};

export async function verifyRecipeBackend({url, key, request = fetch}) {
  const base = assertNonEmpty(url, 'SUPABASE_URL').replace(/\/$/, '');
  const endpoint = new URL(base);
  if (endpoint.protocol !== 'https:') throw new Error('SUPABASE_URL must use HTTPS');
  const headers = {
    apikey: assertNonEmpty(key, 'SUPABASE_PUBLISHABLE_KEY'),
    'Content-Type': 'application/json',
  };
  const fetchWithTimeout = (path, options) => request(path, {
    ...options,
    signal: AbortSignal.timeout(15000),
  });
  const response = await fetchWithTimeout(`${base}/rest/v1/rpc/miga_recipe_snapshot`, {
    method: 'POST', headers, body: '{}',
  });
  if (!response.ok) {
    throw new Error(`Recipe RPC returned HTTP ${response.status}; check that the catalog migration was deployed`);
  }
  const recipes = await response.json();
  if (!Array.isArray(recipes)) throw new Error('Recipe RPC response is not an array');
  const failed = [];
  let checked = 0;
  const root = `${base}/storage/v1/object/public/recipe-photos/`;
  // Check all public photos, not only the first card on the Home screen.
  for (let start = 0; start < recipes.length; start += 5) {
    await Promise.all(recipes.slice(start, start + 5).map(async (recipe) => {
      const path = recipe?.photo?.path;
      const relative = typeof path === 'string' &&
        /^[a-zA-Z0-9_/-]+\.(jpg|jpeg|webp|png)$/.test(path) &&
        !path.includes('..') && !path.startsWith('/');
      const destination = relative ? root + path.split('/').map(encodeURIComponent).join('/') :
        typeof path === 'string' && path.startsWith(root) ? path : null;
      if (!destination) {
        failed.push({id: recipe?.id ?? 'unknown', status: 'invalid photo path'});
        return;
      }
      try {
        let result = await fetchWithTimeout(destination, {method: 'HEAD', headers: {apikey: headers.apikey}});
        if (result.status === 405) {
          result = await fetchWithTimeout(destination, {method: 'GET',
            headers: {apikey: headers.apikey, Range: 'bytes=0-0'}});
        }
        await result.body?.cancel();
        checked++;
        if (!result.ok) failed.push({id: recipe.id, status: `HTTP ${result.status}`});
      } catch (error) {
        failed.push({id: recipe.id, status: String(error)});
      }
    }));
  }
  return {published: recipes.length, checked, failures: failed};
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    const args = process.argv.slice(2);
    if (args.length !== 2 || args[0] !== '--env') {
      throw new Error('Usage: node tool/verify_recipe_backend.mjs --env supabase.env.json');
    }
    const env = JSON.parse(await readFile(resolve(args[1]), 'utf8'));
    const result = await verifyRecipeBackend({url: env.SUPABASE_URL, key: env.SUPABASE_PUBLISHABLE_KEY});
    console.log(`Published recipes: ${result.published}`);
    console.log(`Photos checked: ${result.checked}`);
    if (result.published === 0) {
      console.error('No published recipes. Apply migrations and run the importer with --status published --apply.');
      process.exitCode = 1;
    }
    if (result.failures.length) {
      for (const fail of result.failures.slice(0, 30)) console.error(`${fail.id}: ${fail.status}`);
      console.error(`${result.failures.length} photos unavailable. Re-upload to the public recipe-photos bucket.`);
      process.exitCode = 1;
    }
    if (result.published > 0 && result.failures.length === 0) console.log('All published recipe photos are reachable.');
  } catch (error) {
    console.error(`Catalog verification failed: ${error.message}`);
    process.exitCode = 1;
  }
}
