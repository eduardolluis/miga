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
