# Activar los servicios de Miga

Los cambios locales funcionan sin instalar el servidor. Las funciones en la nube
se mantienen pendientes hasta que se configuren los servicios reales. No incluir
secretos administrativos ni claves de tiendas en el archivo de Flutter.

## Supabase

1. Revisar `supabase/migrations/202610310001_miga_data.sql` y aplicarla con el
   administrador del proyecto o con Supabase CLI (`supabase link` y `supabase db push`).
   No aplicarla a un proyecto distinto al configurado en Miga.
2. Desplegar `delete-account`, `verify-purchase` y `refresh-subscriptions` con
   `supabase functions deploy NOMBRE`. Las dos primeras requieren el JWT del usuario.
3. Los datos se guardan en `miga_documents`, separados por `auth.uid()`, con
   revisiones comparadas en servidor. La copia local v1 se importa sin borrarla.
   Ante conflicto se puede conservar el dispositivo o elegir la versión remota.
4. Las listas compartidas usan una invitación aleatoria de 256 bits, cuyo hash se
   guarda en servidor. Solo propietario e integrantes pueden leerlas; escrituras
   e invitaciones pasan por funciones con control de acceso y revisión.
5. El borrado de cuenta utiliza el usuario del JWT verificado. Las claves
   `service_role` permanecen exclusivamente en Edge Functions. Las claves foráneas
   borran documentos, listas propias, membresías, derechos y tokens de compra.
6. Probar dos cuentas distintas y dos instalaciones de una misma cuenta. Comprobar
   aislamiento, sincronización, edición simultánea, desconexión y recuperación.

Las pruebas ejecutables de PostgreSQL usan PGlite y crean roles y `auth.uid()`
sintéticos para ejecutar la migración completa y verificar RLS. No sustituyen la
prueba del servidor real ni prueban entrega de eventos Realtime:

```sh
npm --prefix supabase ci
npm --prefix supabase test
```

## Apple y Google de acceso

El Bundle ID de iOS es `com.eduardoluisdlcg.miga`. Habilitar Sign in with Apple
en ese App ID y en el proveedor de Supabase; regenerar el perfil de firma si es
necesario. `Runner.entitlements` incluye la capacidad y el cliente envía nonce
SHA-256 a Apple y el nonce original a Supabase. Se conserva el acceso Google
nativo existente. Los Client IDs de Google siguen en el archivo local de Flutter.

Documentación: [Apple en Supabase](https://supabase.com/docs/guides/auth/social-sign-in/auth-apple),
[tokens nativos](https://supabase.com/docs/reference/dart/auth-signinwithidtoken).

## Suscripciones: mantener desactivadas hasta las pruebas reales

Crear primero los productos recurrentes en App Store Connect y Google Play Console.
Los IDs deben ser reales y sus títulos/descripciones localizados deben informar
duración, precio y renovación. En Flutter, añadir a la configuración local:

```json
{
  "MIGA_BILLING_ENABLED": "true",
  "MIGA_STORE_PRODUCTS": "ID_REAL_MENSUAL,ID_REAL_ANUAL",
  "MIGA_PRIVACY_CONTACT": "CONTACTO_REAL"
}
```

Configurar exclusivamente como secretos del servidor:

- `MIGA_BILLING_ENABLED=true`, `MIGA_STORE_PRODUCTS` con los mismos IDs.
- Apple: `APPLE_BUNDLE_ID`, `APPLE_APP_ID` numérico, `APPLE_ISSUER_ID`,
  `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` de App Store Connect.
- Google: `GOOGLE_PACKAGE_NAME=com.eduardoluisdlcg.miga` y
  `GOOGLE_SERVICE_ACCOUNT_JSON`, con acceso a Android Publisher de esa app.
- `SUBSCRIPTION_REFRESH_SECRET`, aleatorio y solo del servidor/programador de tareas.
- Para pruebas: `ALLOW_STORE_SANDBOX=true` y `APPLE_ENVIRONMENT=sandbox`.
  Producción: desactivar sandbox y usar `APPLE_ENVIRONMENT=production`.

El cliente envía el UUID de la cuenta como identificador de compra; el verificador
exige que Apple/Google vinculen la compra a ese mismo UUID. Los certificados raíz
públicos de Apple se incluyen en `_shared/apple_roots.json`, descargados de
[Apple Certificate Authority](https://www.apple.com/certificateauthority/).
Las pruebas sandbox requieren una compilación y una cuenta de la tienda apropiadas.

Programar llamadas POST autenticadas a `refresh-subscriptions` con su secreto.
Procesa lotes; dimensionar frecuencia y tamaño según usuarios y comprobar errores.
Hasta configurar y probar esta tarea, los reembolsos/cancelaciones fuera de la app
no tienen actualización automática garantizada. Nunca habilitar cobros sin ella.

Tras verificar las compras, activar los permisos Pro del servidor como administrador:

```sql
update public.miga_configuration set pro_required = true where id;
```

Un propietario con suscripción vigente puede crear y mantener listas compartidas;
los invitados pueden unirse sin pagar. Al vencer, la lista se puede consultar pero
las escrituras requieren renovar. Los clientes no pueden cambiar esta configuración.
Las herramientas locales avanzadas pasan de beta gratuita a Pro cuando hay productos
de tienda disponibles. No publicar una oferta de pago mientras no estén verificados
los beneficios, precios, términos y restauraciones reales.

Fuentes de integración: [Flutter In-App Purchase](https://pub.dev/packages/in_app_purchase),
[librería oficial de Apple](https://github.com/apple/app-store-server-library-node),
[Google Subscriptions V2](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2/get).

## Probar en la Mac

```sh
git pull --ff-only
flutter pub get
open -a Simulator
flutter run --dart-define-from-file=supabase.env.json
```

Con varios dispositivos, ejecutar `flutter devices` y utilizar `flutter run -d ID`
con el mismo archivo de configuración. El simulador no confirma una compra ni un
inicio de sesión real de las tiendas. Para perfil de rendimiento, usar un dispositivo
físico compatible con `flutter run --profile`.

## Publicación

Completar [el borrador de privacidad](PRIVACY_DRAFT.md), publicarlo en una URL del
responsable y enlazarla en ambas tiendas. Declarar correo/identificador, datos de
preferencias alimentarias, planes, compras y funciones compartidas según la práctica
real. Añadir una URL de solicitud de borrado para Google Play y comprobar borrado en
la app para Apple. Revisar firma, capturas, soporte, clasificación y acceso del
revisor. CI compila y ejecuta pruebas, pero no publica la app ni configura consolas.
