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

  @override
  String get homeGreeting => 'Un gusto tenerte aquí.';

  @override
  String get homeTitle => '¿Qué cocinamos hoy?';

  @override
  String homeMealsPlanned(int count) {
    return '$count de 21 comidas organizadas';
  }

  @override
  String get homeWeek => 'Tu semana';

  @override
  String get homeToday => 'Hoy';

  @override
  String get homeDayPlan => 'En tu mesa';

  @override
  String get homeBreakfast => 'Desayuno';

  @override
  String get homeLunch => 'Almuerzo';

  @override
  String get homeDinner => 'Cena';

  @override
  String get homeEmptyMeal => 'Un espacio para algo rico.';

  @override
  String get homeAddMeal => 'Añadir comida';

  @override
  String get homeEditMeal => 'Editar comida';

  @override
  String get homeMealName => '¿Qué vas a comer?';

  @override
  String get homeMealHint => 'Ej. arroz con vegetales';

  @override
  String get homeMealRequired => 'Escribe el nombre de tu comida.';

  @override
  String get homeSaveMeal => 'Guardar comida';

  @override
  String get homeRemoveMeal => 'Quitar comida';

  @override
  String get homeStorageNotice => 'Tu plan se guarda en este dispositivo.';

  @override
  String get homeLoadError => 'No pudimos cargar tu plan.';

  @override
  String get homeSaveError => 'No pudimos guardar el cambio. Inténtalo de nuevo.';

  @override
  String get homeRetry => 'Reintentar';

  @override
  String get homeAccount => 'Tu cuenta';

  @override
  String get homeSignOutError => 'No pudimos cerrar la sesión. Inténtalo de nuevo.';

  @override
  String get homeInspiration => 'Una idea para tu mesa';

  @override
  String get homeRecipeTitle => 'Salmón al limón y hierbas';

  @override
  String get homeRecipeSubtitle => 'Pocos ingredientes, mucho color.';

  @override
  String get homeRecipeMeta => '30 min · 2 porciones';

  @override
  String get homeViewRecipe => 'Ver receta';

  @override
  String get homeIngredients => 'Ingredientes';

  @override
  String get homeRecipeIngredients => '2 filetes de salmón\n300 g de papas pequeñas\n2 tazas de brócoli\n1 limón\n1 cucharada de aceite de oliva\nHierbas, sal y pimienta al gusto';

  @override
  String get homePreparation => 'Preparación';

  @override
  String get homeRecipeSteps => '1. Precalienta el horno a 200 °C. Corta las papas, mézclalas con parte del aceite y ásalas hasta que empiecen a ablandarse.\n\n2. Añade el salmón y el brócoli a la bandeja. Agrega el aceite restante, el limón y las hierbas.\n\n3. Hornea hasta que el pescado esté cocido y las papas tiernas. Sirve con limón fresco.';

  @override
  String get homeUseRecipe => 'Añadir a mi plan';

  @override
  String get homeNavHome => 'Inicio';

  @override
  String get homeNavPlan => 'Plan';

  @override
  String get homeNavRecipes => 'Recetas';

  @override
  String get homeNavProfile => 'Perfil';

  @override
  String get homeViewPlan => 'Ver plan';

  @override
  String get homeEmptyHeroTitle => 'Tu próxima comida,\na tu gusto.';

  @override
  String get homeEmptyHeroDescription => 'Aún no tienes una comida planificada.';

  @override
  String get homeRecipeIdea => 'Ver una idea';

  @override
  String get homeTodayPlan => 'TU PLAN DEL DÍA';

  @override
  String get homeBudget => 'Presupuesto semanal';

  @override
  String get homeBudgetEmptyTitle => 'Un plan que cuide\ntu bolsillo.';

  @override
  String get homeBudgetEmptyDescription => 'Define cuánto quieres gastar esta semana y registra tus compras.';

  @override
  String get homeSetBudget => 'Definir presupuesto';

  @override
  String get homeEditBudget => 'Editar presupuesto';

  @override
  String get homeBudgetLimit => 'Presupuesto de la semana';

  @override
  String get homeBudgetSpent => 'Gasto registrado';

  @override
  String get homeCurrency => 'Moneda';

  @override
  String get homeBudgetValidation => 'Introduce un importe válido. El presupuesto debe ser mayor que cero.';

  @override
  String get homeBudgetOnTrack => 'Dentro de tu presupuesto.';

  @override
  String get homeBudgetOver => 'Has superado tu presupuesto.';

  @override
  String get homeSave => 'Guardar cambios';

  @override
  String get homeGroceryList => 'Lista de compras';

  @override
  String get homeGroceryEmpty => 'Tu lista empieza aquí.';

  @override
  String get homeGroceryDescription => 'Añade lo que necesitas y márcalo al comprarlo.';

  @override
  String get homeGroceryHint => 'Ej. tomates, 4 unidades';

  @override
  String get homeGroceryAdd => 'Añadir producto';

  @override
  String get homeGroceryRemove => 'Quitar producto';

  @override
  String homeGroceryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos pendientes',
      one: '1 producto pendiente',
    );
    return '$_temp0';
  }

  @override
  String get homeStores => 'Tiendas cercanas';

  @override
  String get homeStoresSubtitle => 'Tu próxima compra';

  @override
  String get homeStoresEmpty => 'Aún no hay tiendas para mostrar.';

  @override
  String get homeStoresDescription => 'Mientras tanto, prepara tu lista para tener todo a mano cuando salgas a comprar.';

  @override
  String get homeProfileTitle => 'Tu espacio en Miga';

  @override
  String get homeCalendarTitle => 'Tu semana, completa.';

  @override
  String get homeCalendarSubtitle => 'Desayunos, almuerzos y cenas, un día a la vez.';

  @override
  String get homePlannedDay => 'Tiene comidas planificadas';

  @override
  String get homeEmptyDay => 'Sin comidas planificadas';

  @override
  String get homeCarouselPlan => 'Ver comida del día';

  @override
  String get homeCarouselBudget => 'Ver presupuesto semanal';
}
