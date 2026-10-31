# Dominican grocery price references

For the separate online supermarket comparison prototype and its launch
restrictions, see [DOMINICAN_PRICE_RESEARCH.md](DOMINICAN_PRICE_RESEARCH.md).

The app queries the public CKAN metadata API:

https://datos.gob.do/api/3/action/package_show?id=precios_productos_primera_necesidad

It follows the CSV resource hosted on `https://proconsumidor.gob.do` and caches
successful reads in memory for six hours. No API key or paid account was needed
for the verified requests. Published rate limits and a service-level guarantee
were not identified; public access does not guarantee future availability.

Dataset: https://datos.gob.do/dataset/precios_productos_primera_necesidad

The catalog declares Open Data Commons Open Database License (ODbL):
https://opendatacommons.org/licenses/odbl/1-0/

Keep source attribution and review the license requirements before redistributing
the dataset or a derived database. The app does not bundle the source database.

## Meaning of the data

The verified export contains periodic observations by product, presentation,
month, year, and establishment category. It does not identify a specific branch
or provide a live checkout quote. Only supermarket rows are offered in Miga.
The JSON export inspected contained identifiers without useful price columns;
the CSV contained the actual observations.

References are selected explicitly by the user. Preserve the original product,
presentation, period, segment, currency and source URL with the selected price.
Never assign a bag, carton or pound price automatically to a recipe quantity.
Editing the amount or changing currency removes the reference attribution.

The current adapter is specific to the Dominican Republic (`DO`, `DOP`). Other
countries need their own adapters; references carry country and currency fields.
Unknown prices remain unknown, and amounts in different currencies are never added
together. Cart checkmarks do not record spending or change estimated list cost.

The budget projection combines manually recorded spending with the known list
cost. It is a partial estimate whenever products lack prices in the budget's
currency. Grocery prices and nearby-store search are independent integrations.

## Failure behavior

Metadata/data timeouts, invalid schema, an unexpected source host or an empty
usable dataset produce a retryable error. Manual price entry remains available.
There is no insecure TLS fallback or fabricated price fallback. Failed reads are
not cached as successful data.

## Automatic shopping estimates

Opening the grocery list or adding an item now requests missing DOP estimates.
An estimate uses an actual fresh matching catalog offer, labeled approximately,
retaining the product, store, package and date. The price is for buying one
package per list quantity, not a calculated cost of the recipe's ingredient
amount. The UI explicitly asks users to review the brand and package.

Non-membership stores are preferred; PriceSmart is a fallback with its club
reference retained. Among candidates the lowest package outlay is used, without
claiming equivalent quantities or cheapest unit cost. Unknown matches remain
unpriced. Manual prices are preserved, checked state survives asynchronous
lookups, and automatic estimates persist through the existing Save changes flow.

## Recipe costs and weekly-budget suggestions

The home budget section now requests ingredient quotes for recipes in the
selected mealtime. RecipeAmounts records approximate cooking quantities for
all nine catalog recipes (two servings each), including seasoning. These
amounts are kitchen assumptions: cup-to-weight conversions, produce weights,
fillet/breast sizes and "to taste" amounts are not measured nutritional yields.

For each compatible package, consumed cost = package price * recipe amount /
package content. Grams, milliliters and counts remain separate; pounds and
ounces convert to grams, liters to milliliters. Unknown units, ambiguous
multipacks and ambiguous approximate-weight packs remain unpriced. A quoted
one-pound approximate pack can use a one-pound basis. Fractions such as 1/2 lb
are parsed as fractions. Recipe quantities do not become whole-package costs.

The estimator rejects obvious ingredient substitutions (tomato soup, garlic
vinegar, quail eggs, blended oil, dried onion flakes, sweet-potato fries, etc.).
It inspects up to 48 catalog results per store, prefers the lowest compatible
consumed cost across Nacional/Sirena/Jumbo, and retains the exact product,
store and lookup date in the cost breakdown. PriceSmart is excluded from these
budget recommendations because membership eligibility is not known.

Meal target = max(0, weekly limit - recorded spending) / remaining meal slots
this week, including the current slot. Each meal means the recipe's stated
servings, not one person's portion. Only fully costed recipes at or below the
target are marked as fitting, and these rank first. Incomplete recipes explicitly
list missing ingredient prices/package sizes; they are never treated as free.
Changing the budget immediately changes fit/ranking without changing recipe
quantities. Non-DOP budgets are not compared against DOP prices.

This is a per-meal planning aid, not a reserved or optimized weekly shopping
plan. Planned meals do not automatically subtract spending. Buying full packs
may require more money than the ingredients consumed in a recipe, and the
lowest ingredient costs may come from multiple stores. The UI states this.

Live dinner verification on 2026-10-31 found incomplete compatible pricing for
all three dinner recipes (including fresh sweet potato, garlic, carrot/celery,
and liquid vegetable stock gaps). These recipes therefore display missing-price
states rather than a claim of fitting the budget. Related processed products
returned by search are rejected rather than substituted silently. Wider catalog
queries alone do not guarantee ingredient coverage; more verified product/unit
coverage is still required for those recipes to receive complete live estimates.
