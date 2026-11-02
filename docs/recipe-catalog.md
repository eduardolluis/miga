# Catálogo de recetas de Miga

Las recetas de producción se leen de Supabase. `lib/` ya no contiene el catálogo,
las cantidades por receta ni una tabla que asigne números a fotografías.

## Datos y publicación

- Migraciones: `supabase/migrations/202611010001_recipe_catalog.sql` y `202611010002_recipe_photo_bucket_public.sql` (asegura que el bucket sea público).
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
Los archivos locales de `supabase/catalog/photos/` son recursos temporales del operador para subir a Storage; se excluyen de Git porque las fotografías publicadas ya viven en Supabase. **No pertenecen a `assets/` ni se empaquetan en la app**.

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

## Poner el catálogo en producción (necesario para ver las fotos)

La migración y la importación son **dos acciones distintas**. El código Flutter
no puede publicar fotos ni recetas por sí solo. Un `flutter run` sin estos pasos
mostrará un catálogo vacío o fotos faltantes. Las 54 fotos originales están en
`supabase/catalog/photos/` para subirlas; **no se empaquetan en la app móvil**.

1. Desde el proyecto, autentica y enlaza la CLI con el proyecto de Supabase
   correcto; revisa el destino antes de aplicar cambios:

   ```sh
   supabase login
   supabase link --project-ref qythwojltifyhlkarzdh
   supabase db push --linked
   ```

   `db push` aplica las migraciones pendientes en orden. No uses `db reset`
   remoto: borraría datos. `supabase db query` no es un comando soportado de la CLI.

2. Consigue la clave **service_role** en el dashboard de Supabase de ese proyecto.
   Es exclusivamente para el terminal del operador: **nunca** en Flutter,
   `supabase.env.json`, Git, capturas ni el ZIP compartido. Configura las dos
   variables de entorno en tu sesión de terminal (sin pegarlas en el chat):

   ```sh
   export SUPABASE_URL='https://qythwojltifyhlkarzdh.supabase.co'
   read -rs 'SUPABASE_SERVICE_ROLE_KEY?Clave service_role: '
   echo
   export SUPABASE_SERVICE_ROLE_KEY
   ```

   Si usas Bash en vez de Zsh, utiliza `read -rs -p 'Clave service_role: ' SUPABASE_SERVICE_ROLE_KEY`.

3. Valida y publica las recetas y sus fotos originales. El importador sube
   primero los archivos con un nombre inmutable basado en su hash, y solo
   después publica el catálogo. Nunca lo ejecutes dentro de la app:

   ```sh
   node tool/import_recipes.mjs --status published
   node tool/import_recipes.mjs --status published --apply
   unset SUPABASE_SERVICE_ROLE_KEY
   ```

   El estado por defecto es `draft`; **usa `--status published`** para que el
   catálogo sea visible a los usuarios. El importador necesita `service_role`
   solo cuando lleva `--apply` y no expone la clave en los logs.

4. Comprueba la API pública y **cada foto** usando la publishable key que ya
   usa Flutter (sin permisos administrativos):

   ```sh
   node tool/verify_recipe_backend.mjs --env supabase.env.json
   flutter run --dart-define-from-file=supabase.env.json
   ```

   El verificador detecta migraciones ausentes, un catálogo en borrador,
   rutas incorrectas y fotos que devuelven 403/404. Si falla, publica primero el
   backend; las modificaciones de Dart no solucionan un objeto inexistente en
   Storage. Puedes volver a ejecutar el importador de forma segura.

## Añadir, editar o retirar recetas

Prepara otro JSON con `schema_version: 1` y un array `recipes`; conserva los IDs
estables para favoritos, planes y compras. Revisa ingredientes, fotos,
alérgenos y datos nutricionales antes de publicar. Ejecuta el importador con
`--file` y `--photos-dir` para fotos nuevas; sin `--apply` valida sin conexión.
`--status draft`, `review`, `published` y `archived` controlan qué ven los
usuarios. Las recetas nuevas **no requieren actualizar Flutter**.

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

## Expansión de 196 recetas

Las fotografías individuales nuevas se guardan en
`supabase/catalog/photos/new/<id-de-receta>.jpg`. El registro de prompts y
destinos está en `reports/recipe-expansion-photo-prompts-2026-11-01.json`;
son imágenes ilustrativas generadas con la herramienta integrada `image_gen`.

El siguiente comando exige que estén las 196 fotografías, comprueba sus
dimensiones y valida las recetas con el mismo importador del catálogo original:

```sh
node tool/publish_recipe_expansion.mjs
```

Produce los manifiestos `recipes-250-import-ready.json` y
`recipes-196-import-ready.json` dentro de `supabase/catalog/`. No publica nada
sin `--apply`. Para publicar, carga la clave administrativa en el entorno del
terminal del operador y ejecuta:

```sh
source /private/tmp/miga-supabase-admin.env
node tool/publish_recipe_expansion.mjs --apply
```

El proyecto de destino se toma de `supabase.env.json`; la clave administrativa
solo se lee del entorno. Se suben las 196 fotos y se actualizan únicamente los
196 IDs nuevos. Después se verifica la instantánea pública que consume Flutter,
el contenido de cada receta importada, la conservación de las 54 originales y
el acceso público a todas las fotografías. Una publicación verificada genera
`reports/recipe-expansion-publication.json` sin credenciales.
