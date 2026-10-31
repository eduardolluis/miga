# Dominican supermarket prices: research and prototype

Research date: 2026-10-30; Jumbo and PriceSmart follow-up: 2026-10-31. This is a technical prototype, not an assertion that
retailer data is licensed for commercial redistribution or that checkout error
has been demonstrated to stay below 10%.

## Sources checked

| Source | Technical result | Scope and restrictions |
| --- | --- | --- |
| Pro Consumidor / Datos Abiertos | CKAN API and CSV work. JSON export lacks useful price columns. | Periodic observations by establishment category, not live branch quotes. The inspected observations were July–September 2026. Catalog declares ODbL. |
| Nacional | Public Magento GraphQL catalog returns product/SKU, stock status, final price and currency. | Default Nacional online store context. Check store context and currency before accepting a quote. Commercial reuse requires a written CCN agreement under published terms. |
| Sirena | Public VTEX catalog returns SKU, EAN where present, seller, offer price and availability. | Catalog may return HTTP 206 for a successful partial result set. Published terms restrict commercial/automated use without permission and distinguish online from physical-store prices. |
| Jumbo | Magento GraphQL works with the public `Store: jumbo` header; default requests return Nacional. | Validate the response base URL is Jumbo before accepting DOP prices. Same CCN commercial agreement restrictions. |
| PriceSmart | Public storefront search middleware returns Dominican catalog offers for Los Prados club 6801 without login or API keys. | Prices are pack amounts in minor units, with club-specific stock. Membership required for shopping. Published terms restrict harvesting and commercial redistribution; permission is unresolved. |
| Supermix | Category content was blocked in the direct check; robots excludes API/search paths. | No scraping workaround or fabricated provider was added. |
| SupermercadosRD | Price comparison exists, but no public integration contract was verified. | Published terms prohibit unauthorized automated extraction and mass commercial redistribution. Not used as a feed. |
| ReefAPI | Documentation advertises VTEX lookup, API-key authentication and credit billing. | Coverage and commercial permission for specific Dominican chains were not independently verified. No account, purchase or integration was created. |

No API key or per-request payment was required for the tested direct retailer
catalog reads. That is not a promise of unlimited access or permission to launch
a commercial integration. Confirm retailer agreements, rate limits, availability
and pricing before distributing or monetizing the adapters. Keep any future paid
provider key on a backend, not in the Flutter binary.

## Implemented flow

1. Grocery list → Compare supermarket prices → choose the list item.
2. Query the supported online catalogs on demand, with bounded result counts.
3. Show products grouped by store, retaining exact SKU/presentation and lookup time.
4. User selects the actual product. Its quoted price and provenance enter the list.
5. Save changes persists the list. Manually edited amounts lose retailer attribution.
6. Nearby-store buttons open Google Maps with the chosen chain in the search query.

The map integration lets Maps handle location permission and nearby results. It
does not independently calculate the nearest branch, establish branch inventory,
or prove that branch has the online price. Price lookup and map lookup are separate.

Unknown, zero, unavailable, foreign-currency and unsupported offers are excluded.
Nacional configurable-product minimum prices are not treated as exact SKU prices.
Only Sirena's first-party seller is accepted. A failing store does not replace its
price with another store's price or an old government observation.

Online offers older than 24 hours are excluded from grocery totals and require
refreshing. This freshness policy reduces stale estimates; it does not establish
a statistical or contractual accuracy bound.

Sirena offers are currently limited to unit-based SKUs with a unit multiplier of
one. Weight/multiplier conversions need an explicit purchase-unit model before
they can safely be included; they are not silently estimated.

## Live verification

The actual Dart adapter was exercised against the public catalogs with `arroz`,
`leche` and `huevos`. Both supported stores returned nonempty offer sets after
handling VTEX's 206 response. Generic searches may return unrelated product
variants; users must choose the intended brand and presentation. There is no
automatic lowest-price claim across products with different sizes or brands.

## How to evaluate the requested 10% target

For the same SKU, package, quantity, chain, branch/channel and observation period:

`absolute percentage error = abs(estimated item price - paid item price) / paid item price * 100`

Use actual checkout/receipt prices as ground truth, recording applicable
promotions, membership/payment conditions and taxes. Compare item prices without
silently mixing shipping costs, online-only promotions or weight differences.
Measure per-item errors as well as full-basket errors; a low mean error does not
prove that no individual item exceeds 10%.

No receipt-validation sample has been collected in this workspace. Consequently,
the prototype does not advertise "within 10%", "90% accurate", or any other
unmeasured accuracy guarantee. A verified product identity and a fresh catalog
response alone cannot establish agreement with a physical branch's checkout.

A single online consistency spot check matched Nacional SKU `2140283` at
RD$339.95 in both GraphQL and the same product page's structured offer. This is
one catalog/page agreement check, not a receipt test or a measured market-wide
maximum error.

## Primary references

- [Pro Consumidor dataset metadata](https://datos.gob.do/api/3/action/package_show?id=precios_productos_primera_necesidad)
- [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/)
- [Nacional terms](https://supermercadosnacional.com/terminos-y-condiciones)
- [Sirena terms](https://nuevo.sirena.do/terminos-y-condiciones)
- [Jumbo terms](https://jumbo.com.do/terminos-y-condiciones)
- [Adobe products query](https://developer.adobe.com/commerce/webapi/graphql/schema/products/queries/products/)
- [VTEX Legacy Search API](https://developers.vtex.com/docs/api-reference/search-api)
- [SupermercadosRD terms](https://supermercadosrd.com/terminos)
- [ReefAPI VTEX documentation](https://reefapi.com/docs/vtex)
- [ReefAPI pricing and authentication](https://reefapi.com/docs)

## Jumbo and PriceSmart verification (2026-10-31)

Jumbo's storefront identifies its store code as `jumbo`. The GraphQL request
explicitly supplies that Store header and validates the returned HTTPS base host.
Without the header the endpoint returns Nacional, which must be rejected.
Live searches returned 11 rice, 12 milk-related and 6 egg offers for Jumbo.

PriceSmart uses a public POST search at
`https://www.pricesmart.com/api/br_discovery/getProductsByKeyword` with
`view_id=DO`, the Spanish catalog and club fields `*_DO_6801`. No retailer keys,
member credentials or browser identifiers are copied into the app. Generic
`price` is zero; `price_DO_6801` is already cents with `fractionDigits=2`.
The adapter accepts positive integer DOP amounts, in-stock/available products,
and excludes flagged weighted products. It shows the full pack and Los Prados
reference club, not a fabricated per-unit estimate or all-branch guarantee.

Live searches returned 8 rice, 12 milk-related and 4 egg offers for PriceSmart.
Examples: Jumbo SKU 2047670 rice 20 lb RD$934.95; PriceSmart SKU 363516 rice
50 lb RD$2,020.00. These are different packages and not a same-product savings
comparison. PriceSmart membership cost is not included in grocery totals.

These are undocumented storefront interfaces, not contracted partner APIs.
PriceSmart's terms sections 6–7 limit personal/noncommercial use and prohibit
harvesting and commercial redistribution. An agreement is needed before a
commercial rollout; technical availability does not supply permission.

- [PriceSmart Dominican storefront](https://www.pricesmart.com/es-do)
- [PriceSmart terms and conditions](https://www.pricesmart.com/en-do/terms-and-conditions)
- [PriceSmart Dominican local policies](https://www.pricesmart.com/es-do/politicas-locales)
