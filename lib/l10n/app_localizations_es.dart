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
}
