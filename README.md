# miga

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Acceso sin contraseña (Supabase)

La app usa Google y códigos por correo para entrar o crear una cuenta.
Apple es visible en iOS, pero su integración queda pendiente y muestra un aviso
localizado al pulsarlo. `AuthService` separa las
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
2. **Google:** configura un cliente OAuth web en Google Cloud y habilita Google en
   Supabase con su Client ID y Client Secret. En Google registra como URI de retorno
   la URL de callback que muestra Supabase (`https://<project-ref>.supabase.co/auth/v1/callback`).
   Si el proyecto de Google está en modo de pruebas, añade los usuarios de prueba.
3. **Apple (pendiente):** el botón muestra un aviso y no inicia OAuth. Para completar
   la integración mediante OAuth en el navegador, configura el App ID, Services ID, dominio y Return URL en Apple
   Developer y habilita el proveedor Apple en Supabase con las credenciales
   correspondientes. Su Return URL es la del callback de Supabase. Los secretos
   de Apple para OAuth requieren renovación; consulta su caducidad antes de publicar.
4. **Regreso al móvil:** en Supabase Authentication → URL Configuration → Redirect
   URLs, añade exactamente `com.eduardodelacruz.miga://login-callback`. El scheme ya
   está registrado en `ios/Runner/Info.plist` y en el manifest de Android. El manejo
   de enlaces de Flutter está desactivado para dejarlo a `supabase_flutter`.
   Tras cambiar estos archivos, recompila la app: hot reload no actualiza esta parte.
5. **Web, si se usa:** añade el origen de la aplicación a las Redirect URLs. En web
   el código usa `Uri.base.origin` para regresar después de OAuth.

El envío de un código o la apertura del navegador no se consideran un acceso
exitoso: hace falta una sesión confirmada por Supabase. Por ahora, al entrar se
muestra una confirmación de sesión con la opción de cerrarla; la pantalla principal
de planificación todavía no está implementada. Al reiniciar se recupera la sesión
que guarda `supabase_flutter`.

### Validación pendiente con cuentas reales

Las pruebas automáticas verifican validación, errores, reenvío, sesión y botones
por plataforma. Tras configurar los proveedores, prueba en dispositivos reales:
correo nuevo y existente, código incorrecto/caducado, cancelación de OAuth, regreso
a la app desde Google, aviso de Apple en ambos idiomas, reinicio y cierre de sesión. No se ha comprobado el
acceso real contra los proveedores desde este repositorio.

Documentación oficial:
- [Códigos por correo](https://supabase.com/docs/guides/auth/auth-email-passwordless)
- [Google](https://supabase.com/docs/guides/auth/social-login/auth-google)
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
Redirect URLs, además de la URL original que sigue usando OAuth:

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
