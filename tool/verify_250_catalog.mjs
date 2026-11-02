import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
const base = new URL('../supabase/catalog/',import.meta.url);
export async function verifyCatalog250() {
  const read = async filename => JSON.parse(await readFile(new URL(filename,base),'utf8'));
  const origin=await read('recipes.json');
  const expanded=await read('recipe-expansion-drafts.json');
  const full=await read('recipes-250-staging.json');
  const units=await read('ingredients.json');
  const prices=await read('estimated-ingredient-prices-DOP.json');
  assert.equal(origin.recipes.length,54,'Preserve original 54');
  assert.equal(expanded.recipes.length,196,'Exactly 196 new recipes');
  assert.equal(full.recipes.length,250,'Exactly 250 total');
  const unique = (items,path) => {
    const all=items.map(r=>path(r));
    assert.equal(new Set(all).size,all.length,'Duplicate identifiers or titles');
  };
  unique(full.recipes,r=>r.id);
  unique(full.recipes,r=>r.es.title.toLowerCase());
  unique(full.recipes,r=>r.en.title.toLowerCase());
  assert.deepEqual(full.recipes.slice(0,54).map(r=>r.id),origin.recipes.map(r=>r.id));
  assert.deepEqual(full.recipes.slice(54).map(r=>r.id),expanded.recipes.map(r=>r.id));
  const counts={breakfast:0,lunch:0,dinner:0};
  let rows=0;
  for (const [index,r] of full.recipes.entries()) {
    assert.match(r.id,/^[a-z0-9]+(-[a-z0-9]+)*$/);
    assert.ok(r.es.title && r.en.title && r.es.description && r.en.description);
    assert.ok(r.es.steps.length>=3 && r.en.steps.length>=3);
    if(index>=54) assert.ok(r.es.ingredients.length===r.amounts.length && r.en.ingredients.length===r.amounts.length);
    assert.ok(r.servings>0 && r.minutes>=1);
    counts[r.slot]++;
    assert.ok(r.amounts.length>=3 && r.amounts.length<30);
    const ingredientKeys = r.amounts.map(a=>a.ingredient);
    assert.equal(new Set(ingredientKeys).size,ingredientKeys.length,`Repeated ingredient in ${r.id}`);
    for (const a of r.amounts) {
      assert.ok(Object.hasOwn(units,a.ingredient), `Unknown ingredient ${a.ingredient} in ${r.id}`);
      if(index>=54) assert.equal(a.unit,units[a.ingredient],`Unit mismatch ${r.id}/${a.ingredient}`);
      else if (a.unit!==units[a.ingredient]) assert.ok(a.unit==='pieces' && a.grams_per_piece>0,`Unpriced legacy quantity in ${r.id}`);
      assert.ok(a.amount>0);
      if(a.unit==='pieces') assert.ok((a.grams_per_piece??100)>0);
    }
    const cost=r.estimated_cost;
    assert.equal(cost.currency,'DOP');assert.equal(cost.estimated,true);
    assert.equal(cost.lines.length,r.amounts.length);
    const subtotal=cost.lines.reduce((s,l)=>s+l.estimated_total_cents,0);
    assert.equal(cost.total_cents,subtotal);
    assert.equal(cost.per_serving_cents,Math.round(subtotal/r.servings));
    for (let n=0;n<cost.lines.length;n++) {
      const a=r.amounts[n],l=cost.lines[n];
      assert.equal(a.ingredient,l.ingredient);
      assert.equal(a.amount,l.amount);
      assert.equal(a.unit,l.unit);
      const canonicalRate=prices.rates_per_canonical_unit[a.ingredient].rate_dop;
      const expectedRate=a.unit==='pieces' && units[a.ingredient]==='grams' ? Number((canonicalRate*a.grams_per_piece).toFixed(3)) : canonicalRate;
      assert.equal(l.unit_price_dop,expectedRate);
      assert.equal(l.estimated_total_cents, Math.max(1,Math.round(a.amount*l.unit_price_dop*100)));
      rows++;
    }
    if(index<54) assert.ok(r.photo?.path,'Existing image unexpectedly missing');
    else {assert.equal(r.photo,null,'No fake images in new recipes'); assert.equal(r.photo_status,'pending_generation');}
    if(index>=54) {
      assert.equal(r.nutrition.estimated,true);
      for(const f of ['calories','protein_grams','carbs_grams','fat_grams']) assert.ok(Number.isSafeInteger(r.nutrition[f]) && r.nutrition[f]>=0);
    }
  }
  assert.deepEqual(counts,{breakfast:78,lunch:98,dinner:74});
  return {all:250,new:196,original:54,counts,pricedRecipes:250,pricedIngredientLines:rows,missingImages:196};
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
 try {console.log(JSON.stringify(await verifyCatalog250(),null,2));}
 catch (e) {console.error(e.stack);process.exitCode=1;}
}
