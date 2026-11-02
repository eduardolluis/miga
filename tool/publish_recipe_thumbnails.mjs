/** Publish pre-sized recipe-card thumbnails; full-size photos stay unchanged. */
import {createHash} from 'node:crypto';
import {readFile, writeFile} from 'node:fs/promises';
import {resolve, dirname, basename, extname} from 'node:path';
import {pathToFileURL} from 'node:url';
import {imageDimensions, importCatalog} from './import_recipes.mjs';
import {verifyRecipeBackend} from './verify_recipe_backend.mjs';

const readJson = async path => JSON.parse(await readFile(path,'utf8'));
const canonical = value => Array.isArray(value) ? value.map(canonical) :
  value && typeof value === 'object' ? Object.fromEntries(Object.keys(value).sort().map(key=>[key,canonical(value[key])])) : value;
const sameJson = (left,right) => JSON.stringify(canonical(left))===JSON.stringify(canonical(right));

async function upload(url,key,path,bytes) {
  const response = await fetch(url+'/storage/v1/object/recipe-photos/'+
    path.split('/').map(encodeURIComponent).join('/'), {
      method:'POST',
      headers:{apikey:key,Authorization:'Bearer '+key,'Content-Type':'image/jpeg',
        'Cache-Control':'max-age=31536000','x-upsert':'false'},
      body:bytes, signal:AbortSignal.timeout(30000),
    });
  if (response.ok || response.status === 409) return;
  const problem = await response.json().catch(()=>({}));
  if (response.status === 400 &&
      (String(problem.statusCode)==='409' || problem.error==='Duplicate')) return;
  throw new Error('Thumbnail upload failed ('+response.status+')');
}

export async function publishThumbnails({apply=false}={}) {
  const root=resolve('supabase/catalog/photos');
  const catalogFile=resolve('supabase/catalog/recipes-250-import-ready-with-thumbnails.json');
  const additionsFile=resolve('supabase/catalog/recipes-196-with-thumbnails.json');
  const [catalog,additionsSource,originals,config]=await Promise.all([
    readJson(catalogFile),
    readJson('supabase/catalog/recipe-expansion-drafts.json'),
    readJson('supabase/catalog/recipes.json'),
    readJson('supabase.env.json'),
  ]);
  if(catalog.recipes?.length!==250 || additionsSource.recipes?.length!==196 ||
      originals.recipes?.length!==54) throw new Error('Expected the published 250-recipe catalog');
  const byId=new Map(catalog.recipes.map(r=>[r.id,r]));
  const originalIds=new Set(originals.recipes.map(r=>r.id));
  const newIds=new Set(additionsSource.recipes.map(r=>r.id));
  if(byId.size!==250 || originalIds.size!==54 || newIds.size!==196 ||
      [...originalIds,...newIds].some((id,i,a)=>a.indexOf(id)!==i) ||
      catalog.recipes.some(r=>!r.photo?.thumbnail_path ||
        r.photo.thumbnail_width!==768 || r.photo.thumbnail_height!==576)) {
    throw new Error('Thumbnail manifest must contain 54 originals and 196 new unique recipes');
  }
  const additions=catalog.recipes.filter(r=>newIds.has(r.id));
  await writeFile(additionsFile,JSON.stringify({schema_version:1,recipes:additions},null,2)+'\n');
  const url=config.SUPABASE_URL?.replace(/\/$/,'');
  const key=process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if(!url || !key) throw new Error('Load SUPABASE_SERVICE_ROLE_KEY in the operator terminal');
  const publicHeaders={apikey:config.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json'};
  const snapshot=async()=>{
    const response=await fetch(url+'/rest/v1/rpc/miga_recipe_snapshot',{
      method:'POST',headers:publicHeaders,body:'{}',signal:AbortSignal.timeout(20000),
    });
    if(!response.ok) throw new Error('Public recipe snapshot returned HTTP '+response.status);
    const rows=await response.json();
    if(!Array.isArray(rows)) throw new Error('Public recipe snapshot is invalid');
    return new Map(rows.map(r=>[r.id,r]));
  };
  const before=await snapshot();
  if(before.size!==250 || [...before.keys()].some(id=>!byId.has(id))) {
    throw new Error('Expected all 250 recipes to be published before thumbnail rollout');
  }
  const sourceChecks=[];
  for(const recipe of catalog.recipes) {
    const path=resolve(root,recipe.photo.thumbnail_path);
    const bytes=await readFile(path);
    const [width,height]=imageDimensions(bytes);
    if(width!==768 || height!==576 || bytes.byteLength>8388608) {
      throw new Error('Invalid 768 x 576 thumbnail for '+recipe.id);
    }
    const hash=createHash('sha256').update(bytes).digest('hex').slice(0,16);
    sourceChecks.push({recipe,path,bytes,storedPath:
      dirname(recipe.photo.thumbnail_path)+'/'+
      basename(path,extname(path))+'-'+hash+extname(path)});
  }
  const dryRun=await importCatalog({file:additionsFile,photosDir:root,status:'published'});
  if(!apply) return {...dryRun,thumbnailFiles:sourceChecks.length,
    thumbnailBytes:sourceChecks.reduce((n,x)=>n+x.bytes.length,0),applied:false};

  // New recipes upload their thumbnail with the existing safe photo importer.
  await importCatalog({file:additionsFile,photosDir:root,status:'published',
    apply:true,env:{SUPABASE_URL:url,SUPABASE_SERVICE_ROLE_KEY:key}});
  // The originals keep all existing metadata; only their thumbnail fields change.
  const originalUpdates=[];
  const originalChecks=sourceChecks.filter(x=>originalIds.has(x.recipe.id));
  for(let offset=0;offset<originalChecks.length;offset+=8) {
    const batch=originalChecks.slice(offset,offset+8);
    await Promise.all(batch.map(item=>upload(url,key,item.storedPath,item.bytes)));
    console.log(`Uploaded original thumbnails ${Math.min(offset+8,originalChecks.length)}/${originalChecks.length}`);
  }
  for(const item of originalChecks) {
    const data=structuredClone(before.get(item.recipe.id));
    data.photo.thumbnail_path=item.storedPath;
    data.photo.thumbnail_width=768;
    data.photo.thumbnail_height=576;
    originalUpdates.push({id:item.recipe.id,data,status:'published'});
  }
  const response=await fetch(url+'/rest/v1/miga_recipes?on_conflict=id',{
    method:'POST',
    headers:{apikey:key,Authorization:'Bearer '+key,'Content-Type':'application/json',
      Prefer:'resolution=merge-duplicates,return=minimal'},
    body:JSON.stringify(originalUpdates),
    signal:AbortSignal.timeout(30000),
  });
  if(!response.ok) throw new Error('Supabase rejected original thumbnail metadata ('+response.status+')');

  const after=await snapshot();
  for(const id of originalIds) {
    const expected=structuredClone(before.get(id));
    const thumb=sourceChecks.find(x=>x.recipe.id===id);
    expected.photo.thumbnail_path=thumb.storedPath;
    expected.photo.thumbnail_width=768;
    expected.photo.thumbnail_height=576;
    if(!sameJson(after.get(id),expected)) {
      throw new Error('Original recipe metadata changed unexpectedly: '+id);
    }
  }
  for(const recipe of additions) {
    const original=recipe.photo.path;
    const mainBytes=await readFile(resolve(root,original));
    const mainHash=createHash('sha256').update(mainBytes).digest('hex').slice(0,16);
    const thumb=sourceChecks.find(x=>x.recipe.id===recipe.id);
    const expected=structuredClone(recipe);
    expected.photo.path=original.replace(/(\.[^.]+)$/,'-'+mainHash+'$1');
    expected.photo.thumbnail_path=thumb.storedPath;
    if(!sameJson(after.get(recipe.id),expected)) {
      throw new Error('Published thumbnail metadata mismatch: '+recipe.id);
    }
  }
  const checked=[];
  for(let offset=0;offset<sourceChecks.length;offset+=20) {
    const batch=sourceChecks.slice(offset,offset+20);
    checked.push(...await Promise.all(batch.map(async item=>{
      const photoUrl=url+'/storage/v1/object/public/recipe-photos/'+
        item.storedPath.split('/').map(encodeURIComponent).join('/');
      const result=await fetch(photoUrl,{method:'HEAD',signal:AbortSignal.timeout(15000)});
      await result.body?.cancel();
      return result.ok;
    })));
  }
  if(checked.length!==250 || checked.some(ok=>!ok)) throw new Error('Some public thumbnails are unreachable');
  const fullPhotos=await verifyRecipeBackend({url,key:config.SUPABASE_PUBLISHABLE_KEY});
  if(fullPhotos.failures.length || fullPhotos.published!==250) {
    throw new Error('Full-size recipe photos failed verification');
  }
  const result={recipes:250,thumbnailsPublished:250,fullPhotosChecked:250,
    thumbnailsChecked:checked.length,thumbnailBytes:sourceChecks.reduce((n,x)=>n+x.bytes.length,0),
    originalRecipesPreserved:54,newRecipesUpdated:196,applied:true,
    verifiedAt:new Date().toISOString()};
  await writeFile('reports/recipe-thumbnail-publication.json',JSON.stringify(result,null,2)+'\n');
  return result;
}

if(process.argv[1] && import.meta.url===pathToFileURL(resolve(process.argv[1])).href) {
  const args=process.argv.slice(2);
  try {
    if(args.length>1 || args.some(a=>a!=='--apply')) {
      throw new Error('Usage: node tool/publish_recipe_thumbnails.mjs [--apply]');
    }
    console.log(JSON.stringify(await publishThumbnails({apply:args.includes('--apply')}),null,2));
  } catch(error) {
    console.error(error.message);
    process.exitCode=1;
  }
}
