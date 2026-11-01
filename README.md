> **Corrección de fuentes (2026-10-31):** Este proyecto no necesita `assets/fonts/`. Usa Georgia (fuente serif del sistema en iOS).

# Miga 💚

**Planifica qué cocinar, organiza tu compra y controla tu presupuesto semanal.**
Aplicación móvil Flutter para iOS y Android, bilingüe (español/inglés),
con recetas, calendario semanal, despensa, lista automática de compras,
referencias de precios y sincronización opcional con Supabase.

La identidad visual original de Miga utiliza crema, verde oliva y tipografía
serif. Los servicios de pago se mantienen desactivados hasta su configuración
real con Apple/Google y validación en servidor.



## Recetas y recursos

El catálogo inicial migra **54 recetas (18 desayunos, 18 almuerzos y 18 cenas)**
a Supabase, con nombres, pasos e ingredientes en español e inglés. Las recetas
y las fotografías descargadas usan caché local; las nuevas publicaciones no
requieren actualizar la app. Consulta la [guía del catálogo](docs/recipe-catalog.md).

## Organización del código

La aplicación se organiza por funcionalidades en `lib/features/`, con la composición
y navegación en `lib/app/` y los temas compartidos en `lib/core/`. Las pruebas reflejan
esa estructura. Consulta la arquitectura para ubicar pantallas,
modelos, contratos y almacenamiento, y conocer las reglas para añadir código.

## Acceso sin contraseña (Supabase)

La app usa Google y códigos por correo para entrar o crear una cuenta.
Apple usa acceso nativo en iOS con nonce; necesita habilitar el App ID y el proveedor de Supabase. `AuthService` separa las
llamadas de Supabase de la pantalla; `SupabaseAuthService` es la implementación
real. Las pruebas usan un servicio simulado y no envían correos.

### Ejecutar

Usa un archivo local `supabase.env.json` (ignorado por Git) con `SUPABASE_URL` y
`SUPABASE_PUBLISHABLE_KEY`. Solo debe contener la clave pública, nunca `service_role`.

```sh
flutter run --dart-define-from-file=supabase.env.json
```

### Configuración externa necesaria

1. **Correo:** habilita Email en Supabase Authentication y permite nuevos registros.
   En Email Templates → Confirm sign up y Magic link or OTP, incluye `{{ .Token }}` en el cuerpo para que
   llegue un código que se pueda introducir en la app. El template predeterminado
   con `{{ .ConfirmationURL }}` envía un enlace, que no corresponde a esta pantalla.
   Configura SMTP para enviar a usuarios reales. La app acepta códigos numéricos de
   6 dígitos y deja que Supabase compruebe validez, caducidad y límites.
2. **Google:** usa el SDK nativo en Android/iOS y OAuth en web. El cliente OAuth web
   existente se reutiliza como `GOOGLE_WEB_CLIENT_ID`; también hay que registrar
   las aplicaciones Android/iOS como se explica en **Google nativo** más abajo.
   Habilita Google en Supabase con el Client ID y Client Secret del cliente web.
   El secreto se guarda únicamente en Supabase. Para OAuth web, registra como URI
   de retorno `https://<project-ref>.supabase.co/auth/v1/callback` en Google Cloud.
   Si Google está en modo de pruebas, añade los usuarios de prueba.
3. **Apple:** habilita Sign in with Apple para `com.eduardoluisdlcg.miga` en
   Apple Developer, actualiza la firma y habilita el proveedor Apple de Supabase.
   El entitlement está incluido. El acceso nativo envía un nonce SHA-256 a Apple
   y el original a Supabase; la sesión se publica solo tras el intercambio válido.
   Consulta la configuración de servicios.
4. **Enlaces de correo al móvil:** en Supabase Authentication → URL Configuration → Redirect
   URLs, añade exactamente `com.eduardodelacruz.miga://login-callback`. El scheme ya
   está registrado en `ios/Runner/Info.plist` y en el manifest de Android. El manejo
   de enlaces de Flutter está desactivado para dejarlo a `supabase_flutter`.
   Tras cambiar estos archivos, recompila la app: hot reload no actualiza esta parte.
5. **Web, si se usa:** añade el origen de la aplicación a las Redirect URLs. En web
   el código usa `Uri.base.origin` para regresar después de OAuth.

El envío de un código o la selección de una cuenta de Google no se consideran un acceso
exitoso: hace falta una sesión confirmada por Supabase. Al entrar se abre el Home
con el resumen del día, el calendario semanal, recetas y perfil. El cierre de sesión
está en Perfil. Al reiniciar se recupera la sesión que guarda `supabase_flutter`.

El plan de comidas, el presupuesto semanal y la lista de compras se guardan en el
dispositivo con `shared_preferences`, separados por cuenta. La planificación y el
registro de gastos son manuales. El Home propone recetas distintas según la hora
local, y permite añadir sus ingredientes a la lista. Tiendas abre una búsqueda real
en mapas. Consulta el diseño del Home
para ver capturas, alcance y recursos gráficos.

### Validación pendiente con cuentas reales

Las pruebas automáticas verifican validación, errores, reenvío, sesión y botones
por plataforma. Tras configurar los proveedores, prueba en dispositivos reales:
correo nuevo y existente, código incorrecto/caducado, cancelación del selector de
Google, sesión después del acceso nativo, cambio de cuenta, aviso de Apple en ambos
idiomas, reinicio y cierre de sesión. No se ha comprobado el
acceso real contra los proveedores desde este repositorio.

### Google nativo

Android usa `google_sign_in` 7 e iOS su adaptador oficial `google_sign_in_ios`.
Ambos entregan el ID token y el access token a
`Supabase.auth.signInWithIdToken`. En Android se presenta el selector de cuentas
del sistema. En iOS el SDK de Google puede presentar una ventana de autenticación
del sistema; Google controla esa interfaz. La app web conserva OAuth.
Cancelar el selector no muestra un error ni crea una sesión. Un fallo móvil no
abre el navegador como alternativa. Google se inicializa al pulsar el botón;
la falta de sus IDs no impide entrar por correo.

Los tres clientes OAuth se crean en el **mismo proyecto de Google Cloud**, en
Google Auth Platform → Clients (o APIs & Services → Credentials).

1. **Web:** reutiliza el cliente existente. Añade su ID a `supabase.env.json` con
   la clave `GOOGLE_WEB_CLIENT_ID`. Es el `serverClientId` del SDK y debe estar
   permitido en Authentication → Providers → Google de Supabase.
2. **Android:** crea un cliente OAuth de tipo Android. El paquete actual es
   `com.eduardoluisdlcg.miga` (`applicationId` en `android/app/build.gradle.kts`). Introduce
   el SHA-1 del certificado que firma esa compilación. Puedes consultarlo con:

   ```sh
   keytool -list -v -keystore "$HOME/.android/debug.keystore" \
     -alias androiddebugkey -storepass android -keypass android
   ```

   El cliente Android registra paquete y certificado; su Client ID no se pasa
   a Dart. La integración usa el ID web sin necesitar Firebase ni
   `google-services.json`. Para publicar, registra también el certificado de
   producción/Play App Signing. Si cambias el `applicationId`, actualiza el registro.
3. **iOS:** crea un cliente OAuth de tipo iOS con Bundle ID
   `com.eduardoluisdlcg.miga`. Añade su Client ID como `GOOGLE_IOS_CLIENT_ID` en
   `supabase.env.json`. En `ios/Runner/Info.plist`, dentro del array existente de
   `CFBundleURLTypes`, añade otro diccionario con el ID iOS invertido:

   ```xml
   <dict>
     <key>CFBundleTypeRole</key>
     <string>Editor</string>
     <key>CFBundleURLSchemes</key>
     <array>
       <string>com.googleusercontent.apps.TU_ID_IOS</string>
     </array>
   </dict>
   ```

   Para `123-abc.apps.googleusercontent.com`, el scheme es
   `com.googleusercontent.apps.123-abc`. Conserva también el scheme de Miga
   para los enlaces de correo. En Supabase → Authentication → Providers → Google,
   deja **Skip nonce check apagado**: esta app envía un nonce explícito en iOS.

En cada intento iOS genera un nonce con 32 bytes de `Random.secure`, envía su
SHA-256 hexadecimal a Google y el original a Supabase para validarlo. El adaptador
iOS se crea e inicializa una vez por intento: el singleton de `google_sign_in` 7
solo permite fijar el nonce al inicializarse y no sirve para renovarlo por intento.
Los intentos concurrentes se rechazan para evitar que compartan configuración.
Los nonces y los tokens no se guardan en los registros de diagnóstico.

Después de recompilar, comprueba en un iPhone real con **Skip nonce check apagado**:
entrar, cerrar sesión y volver a entrar; cancelar el selector y reintentar. Los
tests verifican el hash y la renovación, pero no sustituyen esta comprobación
con Google y Supabase reales.

`supabase.env.example.json` muestra las cuatro claves de configuración. No contiene
credenciales reales; copia los valores a tu archivo local existente sin perder
los de Supabase. Reinicia con `flutter run --dart-define-from-file=supabase.env.json`;
los plugins, los Client IDs y el scheme de iOS requieren recompilar.

Si solo existe el cliente web, el código queda preparado, pero el acceso móvil
real necesita completar los registros anteriores. Los tests simulan Google y
Supabase y no validan la configuración de Google Cloud.

Documentación oficial:
- [Códigos por correo](https://supabase.com/docs/guides/auth/auth-email-passwordless)
- [Google](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [SDK Google para Flutter](https://pub.dev/packages/google_sign_in)
- [Configuración Android](https://pub.dev/packages/google_sign_in_android)
- [Configuración iOS](https://pub.dev/packages/google_sign_in_ios)
- [Apple](https://supabase.com/docs/guides/auth/social-sign-in/auth-apple)
- [OAuth en Flutter](https://supabase.com/docs/reference/dart/auth-signinwithoauth)

### Plantilla de correo de Miga

Copia `supabase/templates/magic_link.html` en las plantillas **Confirm sign up** y
**Magic link or OTP** de Supabase. Usa el asunto de `supabase/templates/subject.txt`.
La plantilla anuncia 10 minutos: configura **Email OTP Expiration = 600 segundos**
en los ajustes del proveedor Email antes de usarla. El HTML no cambia la caducidad.
Incluye `{{ .Token }}` y un botón con `{{ .ConfirmationURL }}` como alternativa;
ambos usan el mismo acceso de un solo uso. Si caduca, se necesita uno nuevo.
`sendCode` ahora incluye `emailRedirectTo` para volver al móvil desde el enlace;
recuerda permitir la Redirect URL descrita arriba. Prueba el enlace en el mismo
dispositivo donde lo solicitaste, porque el flujo PKCE guarda el verificador allí.

### Idioma del correo

`AuthScreen` toma el idioma resuelto por Flutter y lo pasa a `sendCode`.
El servicio normaliza a `es` o `en` (inglés como valor predeterminado) y envía
`data.language` para cuentas nuevas. La plantilla usa ese metadato como respaldo.
Para cuentas existentes en móvil, el idioma de cada solicitud tiene prioridad
mediante `.RedirectTo`, sin tener que cambiar metadatos antes de entrar.

Añade también estas dos URLs exactas en Authentication → URL Configuration →
Redirect URLs, además de la URL original de callback móvil:

```text
com.eduardodelacruz.miga://login-callback?language=es
com.eduardodelacruz.miga://login-callback?language=en
```

En web, la plantilla usa el metadato guardado en la cuenta. Si se habilita ese
cliente, hay que extender las condiciones de `.RedirectTo` a sus URLs de retorno
permitidas para que también siga el idioma de cada solicitud. Sin metadato ni
una coincidencia móvil, el correo sale en inglés.

La plantilla se procesa en Supabase; guardar el archivo local no la publica.
Copia el mismo HTML en ambas plantillas del dashboard. El asunto entregado es
bilingüe y fijo. No se ha verificado la entrega real de ambas variantes desde
este entorno: comprueba registro nuevo y acceso de una cuenta existente en ambos
idiomas tras guardar las plantillas y las URLs.

## Planificación, compras y servicios

El checklist de implementación detalla las
funciones disponibles y las comprobaciones que requieren servicios/dispositivos
reales. Porciones, favoritas, preferencias, despensa, plan automático y cantidades
comparten los mismos modelos. El historial usa gastos registrados por el usuario,
separados de las estimaciones. Los precios sin cobertura permanecen incompletos.

La copia local funciona sin conexión. La sincronización y las listas compartidas
necesitan aplicar la migración de Supabase y desplegar sus funciones; el código
no las despliega automáticamente. Los cobros están desactivados por defecto.
Consulta SERVICES_SETUP.md antes de activar servicios,
suscripciones o publicación. La información de privacidad tiene un
borrador pendiente de completar.

Además de `flutter analyze` y `flutter test`, se comprueba SQL/RLS con:

```sh
npm --prefix supabase ci
npm --prefix supabase test
```


## Quick Actions (31 Oct 2026)

Las acciones rápidas incluyen recetas según la despensa, alternativas económicas, Surprise me y generación del plan semanal. La cuota gratuita requiere aplicar `supabase/migrations/202610310002_surprise_quota.sql`.

## Catálogo remoto de recetas

El catálogo, sus cantidades y fotos se administran en Supabase. La app conserva
una caché de datos reales para uso sin conexión; las recetas no se compilan en Dart.
La importación inicial conserva los IDs de las 54 recetas existentes.
Consulta [la guía de publicación e importación](docs/recipe-catalog.md).
