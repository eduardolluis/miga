# Catálogo de recetas de Miga

Las recetas de producción se leen de Supabase. `lib/` ya no contiene el catálogo,
las cantidades por receta ni una tabla que asigne números a fotografías.

## Datos y publicación

- Migración: `supabase/migrations/202611010001_recipe_catalog.sql`.
- Tabla: `public.miga_recipes`; el ID estable es el mismo que usan favoritos y planes.
- Contenido: JSON con traducciones `es`/`en`, pasos, porciones base, cantidades,
  unidades, nutrición opcional, etiquetas, procedencia y foto con dimensiones.
- Estados editoriales: `draft`, `review`, `published`, `archived`.
- Las aplicaciones anónimas y autenticadas solo pueden leer filas `published`.
  Las escrituras requieren un operador con `service_role`.
- Fotos: bucket público `recipe-photos`. La herramienta sube nombres que incluyen
  el hash del archivo para evitar sobrescrituras y cachés de fotos desactualizadas.
- Los datos nutricionales originales se migraron como **estimados**. La migración
  conserva el contenido existente; no supone una revisión editorial o nutricional.

El manifiesto `supabase/catalog/recipes.json` conserva las 54 recetas existentes
como entrada de migración/importación. **No se incluye en el binario Flutter.**
Los archivos de `assets/images/recipes/v2/` también son entradas del importador y
fixtures de pruebas, excluidos de los assets de producción.

## Añadir y actualizar recetas

Preparar un JSON independiente con `schema_version: 1` y un array `recipes`.
Usar la estructura de una entrada del manifiesto existente, un ID nuevo y estable,
ambas traducciones y cantidades explícitas para las porciones indicadas en
`servings`. `nutrition` contiene valores **por porción**, no por receta completa.
`photo.path` es una ruta relativa al directorio de fotos del operador.

Los ingredientes admitidos y sus unidades canónicas están en
`supabase/catalog/ingredients.json`. Se pueden publicar nuevas combinaciones de
esos ingredientes sin actualizar la app. Incorporar un ingrediente nuevo requiere
actualizar también su modelo, clasificación dietética, ilustración y validación
SQL; el importador rechaza ingredientes desconocidos en vez de omitirlos.

Validar contenido y archivos locales, sin credenciales ni escrituras remotas:

```sh
node tool/import_recipes.mjs --file /ruta/recetas.json --photos-dir /ruta/fotos
```

La validación comprueba IDs únicos, traducciones, cantidades, unidades,
metadatos nutricionales, rutas y dimensiones reales de los archivos.
Las instrucciones, alérgenos, procedencia/licencias de fotos y nutrición deben
revisarse editorialmente antes de publicar; esas revisiones no se pueden deducir
solo de que un JSON tenga el formato correcto.

La opción recomendada es usar la sesión autenticada de la CLI de Supabase,
sin extraer ni guardar claves administrativas:

```sh
node tool/import_recipes.mjs --file /ruta/recetas.json --photos-dir /ruta/fotos --cli --project-ref TU_PROJECT_REF --apply
node tool/import_recipes.mjs --file /ruta/recetas.json --photos-dir /ruta/fotos --cli --project-ref TU_PROJECT_REF --status published --apply
```

El proyecto de esta app es `qythwojltifyhlkarzdh`; comprueba siempre el destino.
La herramienta usa `supabase storage cp` y `supabase db query` con la sesión de la
CLI. Los archivos temporales solo contienen fotos y el JSON público del catálogo.

Para automatizaciones que ya tengan `SUPABASE_URL` y
`SUPABASE_SERVICE_ROLE_KEY` disponibles **solo en el entorno del operador**,
también se admite la API directa. Importar inicialmente como borradores:

```sh
node tool/import_recipes.mjs --file /ruta/recetas.json --photos-dir /ruta/fotos --apply
```

Después de revisar, publicar exactamente ese archivo:

```sh
node tool/import_recipes.mjs --file /ruta/recetas.json --photos-dir /ruta/fotos --status published --apply
```

También se admiten `--status review` y `--status archived`. Para actualizar una
receta publicada se conserva su ID y se especifica `--status published`;
el estado predeterminado es siempre `draft`. No se borra el resto del catálogo.
No se deben guardar claves de administración en `supabase.env.json`, Dart,
archivos versionados ni parámetros visibles en la línea de comandos.

Primera importación de las 54 recetas migradas:

```sh
node tool/import_recipes.mjs --status published
node tool/import_recipes.mjs --status published --cli --project-ref qythwojltifyhlkarzdh --apply
```

Aplicar primero la migración SQL al proyecto previsto. En instalaciones ya
existentes puede ejecutarse con `supabase db query --linked --project-ref
TU_PROJECT_REF --file supabase/migrations/202611010001_recipe_catalog.sql`.

Las fotos se suben primero. Si falla una subida, no se escriben metadatos.
Los 54 documentos se guardan en una única operación transaccional. Reintentar
una importación es seguro: los archivos son inmutables por hash y el upsert usa
el ID estable. Un fallo final puede dejar fotos sin referencias, pero no un
catálogo parcialmente actualizado.

## Funcionamiento de la app

`RecipeRepository` obtiene una instantánea consistente mediante
`miga_recipe_snapshot`, la valida y conserva una copia local por proyecto.
Una caché válida se muestra inmediatamente y se revalida en segundo plano.
Sin caché y sin conexión se muestra un error con reintento, nunca recetas falsas.
Una respuesta inválida no reemplaza el último catálogo válido.

La búsqueda por título/idioma, tipo de comida y paginación se ejecuta mediante
`miga_search_recipes`. Antes de consultar, la app calcula los IDs elegibles y su
orden según restricciones, despensa, favoritos y presupuesto. Estos criterios
se calculan con las porciones y precios particulares del hogar. Si falla una
consulta se usa el catálogo real guardado y se señala el modo sin conexión.

Se descarga la instantánea completa para que los planes y las cantidades de
compras funcionen sin conexión, aunque la pantalla del catálogo consulte páginas
de seis recetas. Esta arquitectura está pensada para el catálogo inicial de
cientos de recetas; un catálogo de decenas de miles requeriría sincronización
incremental e índices de búsqueda adicionales.

Los datos descargados persisten entre reinicios. Las fotos remotas usan caché de
archivos en Android/iOS una vez que se han abierto; no se descargan todas de golpe
y la caché puede ser eliminada por el sistema. La versión web no garantiza la
misma persistencia de imágenes. Los skeletons conservan el espacio de las fotos.

Los planes existentes conservan sus IDs y porciones. Las recetas previamente
descargadas que se retiran del catálogo siguen resolviéndose dentro de planes
antiguos, pero ya no aparecen como recomendaciones o resultados nuevos.

## Comprobaciones

```sh
flutter analyze
flutter test
npm --prefix supabase test
```

Las pruebas cubren caché, reinicios sin conexión, respuestas inválidas, porciones
base distintas de dos, planes históricos, búsqueda y paginación remotas,
publicación, permisos de lectura/escritura e importaciones sin cambios parciales.
Los fixtures y repositorios en memoria se inyectan exclusivamente desde `test/`.
