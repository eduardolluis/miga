// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get onboardingIntro => 'Comer bien empieza con un buen plan.';

  @override
  String onboardingStep(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get welcomeTitle => 'Tu semana, a tu gusto.';

  @override
  String get welcomeDescription => 'Planea tus comidas y organiza tus compras fácilmente.';

  @override
  String get planTitle => 'Planifica tu semana.';

  @override
  String get planDescription => 'Arma un menú que se adapte a tus gustos y a tu rutina.';

  @override
  String get shoppingTitle => 'Organiza tus compras.';

  @override
  String get shoppingDescription => 'Reúne en una lista todo lo que necesitas para tus recetas.';

  @override
  String get storesTitle => 'Explora tiendas cercanas.';

  @override
  String get storesDescription => 'Encuentra supermercados cerca de ti.';

  @override
  String get skip => 'Saltar';

  @override
  String get next => 'Siguiente';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get noAccount => '¿No tienes una cuenta?';

  @override
  String get haveAccount => '¿Ya tienes una cuenta?';

  @override
  String get emailRequired => 'Introduce tu correo';

  @override
  String get emailInvalid => 'Introduce un correo válido';

  @override
  String get passwordRequired => 'Introduce tu contraseña';

  @override
  String get passwordMinLength => 'La contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden';

  @override
  String get onboardingPlanIntro => 'Un menú que va contigo.';

  @override
  String get onboardingShoppingIntro => 'Todo lo que necesitas, en una lista.';

  @override
  String get onboardingStoresIntro => 'Tu próxima compra, más cerca.';

  @override
  String get authTitle => 'Tu mesa empieza aquí.';

  @override
  String get authSubtitle => 'Entra o crea tu cuenta con tu opción favorita. Sin contraseña.';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get orWithEmail => 'o con tu correo';

  @override
  String get emailMeCode => 'Enviarme un código';

  @override
  String get checkEmail => 'Revisa tu correo.';

  @override
  String codeSentTo(String email) {
    return 'Introduce el código que enviamos a $email.';
  }

  @override
  String get emailCode => 'Código de verificación';

  @override
  String get verifyCode => 'Verificar y continuar';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String resendIn(int seconds) {
    return 'Reenviar en $seconds s';
  }

  @override
  String get changeEmail => 'Usar otro correo';

  @override
  String get codeRequired => 'Introduce el código completo de tu correo.';

  @override
  String get invalidCode => 'El código no es válido o ha expirado. Solicita uno nuevo.';

  @override
  String get authError => 'No pudimos completar el acceso. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get authRateLimited => 'Espera un momento antes de solicitar otro código.';

  @override
  String get authUnavailable => 'El acceso todavía no está configurado.';

  @override
  String get authSuccess => 'Ya estás en Miga.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get authBrowserError => 'No pudimos abrir el navegador para iniciar sesión. Comprueba que Safari esté disponible e inténtalo de nuevo.';

  @override
  String get appleSignInUnavailable => 'El inicio de sesión con Apple todavía no está disponible.';
}
