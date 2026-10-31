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
  String get homeGroceryDescription => 'Añade productos, introduce precios y marca lo que vas poniendo en el carrito.';

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

  @override
  String get homeGoodMorning => 'Buenos días';

  @override
  String get homeGoodAfternoon => 'Buenas tardes';

  @override
  String get homeGoodEvening => 'Buenas noches';

  @override
  String get homeIdeasBreakfast => 'Para tu desayuno';

  @override
  String get homeIdeasLunch => 'Para tu almuerzo';

  @override
  String get homeIdeasDinner => 'Para tu cena';

  @override
  String get homeIdeasNow => 'Desliza entre las recetas para este momento del día.';

  @override
  String get homeIdeasManual => 'Desliza entre las recetas del momento que elegiste.';

  @override
  String get homeChangeMeal => 'Cambiar momento del día';

  @override
  String get homeUseTime => 'Según la hora actual';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String recipeServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count porciones',
      one: '1 porción',
    );
    return '$_temp0';
  }

  @override
  String get recipeSearch => 'Buscar una receta';

  @override
  String get recipeAll => 'Todas';

  @override
  String get recipeNoResults => 'No encontramos recetas con ese nombre.';

  @override
  String get recipeAddIngredients => 'Añadir ingredientes a la lista';

  @override
  String get recipeIngredientsAdded => 'Ingredientes añadidos';

  @override
  String get homeOpenMaps => 'Abrir en mapas';

  @override
  String get homeMapsUnavailable => 'No pudimos abrir los mapas. Inténtalo de nuevo.';

  @override
  String get homeGoodNight => 'Buenas noches';

  @override
  String get recipeHaveIngredients => '¿Qué tienes en casa?';

  @override
  String get recipeIngredientsHint => 'Marca tus ingredientes. Verás recetas que usen al menos uno, con las mejores coincidencias primero.';

  @override
  String get recipeClearIngredients => 'Limpiar';

  @override
  String recipeIngredientMatch(int have, int missing) {
    return '$have ingredientes disponibles · $missing por conseguir';
  }

  @override
  String get proComingSoon => 'Próximamente';

  @override
  String get proOfferTitle => 'Menos planificación. Más tiempo para ti.';

  @override
  String get proDiscover => 'Descubre Miga Pro';

  @override
  String get proIntroduction => 'Tus herramientas de cada día siguen siendo gratis. Estamos preparando Pro para ayudarte con más de la planificación.';

  @override
  String get proFreePlan => 'Miga Gratis';

  @override
  String get proFreeDescription => 'Todo lo que puedes usar hoy, sin costo.';

  @override
  String get proFreePlanning => 'Planifica tus comidas y edita tu presupuesto semanal';

  @override
  String get proFreeRecipes => 'Explora recetas y filtra por los ingredientes que tienes';

  @override
  String get proFreeShopping => 'Crea tu lista y marca lo que vas comprando';

  @override
  String get proInDevelopment => 'Próximamente · Funciones en desarrollo';

  @override
  String get proAutomaticPlans => 'Tu semana planificada';

  @override
  String get proAutomaticPlansDescription => 'Menús semanales automáticos según tus preferencias y la cantidad de personas en casa.';

  @override
  String get proPantryPlans => 'Aprovecha lo que ya tienes';

  @override
  String get proPantryPlansDescription => 'Crea un menú completo con tus ingredientes disponibles, más allá del filtro gratuito de recetas.';

  @override
  String get proSharedLists => 'Una lista para toda la casa';

  @override
  String get proSharedListsDescription => 'Comparte una lista y mantén sincronizadas las compras de todos.';

  @override
  String get proLaunchNote => 'Las suscripciones Pro todavía no están disponibles. Anunciaremos el precio al lanzar. Tus herramientas gratuitas siguen disponibles.';

  @override
  String get proKeepPlanning => 'Seguir usando Miga Gratis';

  @override
  String get carouselPrevious => 'Receta anterior';

  @override
  String get carouselNext => 'Siguiente receta';

  @override
  String carouselPosition(int current, int total) {
    return '$current de $total recetas';
  }

  @override
  String get groceryManualPrice => 'Precios introducidos por ti, no verificados por una tienda.';

  @override
  String get groceryUnitPrice => 'Precio por producto';

  @override
  String get groceryQuantity => 'Cantidad de productos';

  @override
  String get groceryPriceInvalid => 'Introduce un precio con hasta 2 decimales.';

  @override
  String get groceryQuantityInvalid => 'Introduce un número entero entre 1 y 999.';

  @override
  String get groceryRemovePrice => 'Quitar precio';

  @override
  String get groceryYourPrice => 'Tu precio';

  @override
  String get groceryAddPrice => 'Añadir precio';

  @override
  String groceryEstimate(String amount) {
    return 'Estimado de la lista: $amount';
  }

  @override
  String get groceryPricesNeeded => 'Añade precios para estimar tu compra';

  @override
  String groceryPricesMissing(Object count) {
    return 'A $count productos todavía les falta precio';
  }

  @override
  String groceryPriceCoverage(int count, String currency) {
    return '$count productos no tienen precio en $currency y no se incluyen en el estimado.';
  }

  @override
  String groceryCartProgress(int checked, int total) {
    return '$checked de $total productos en el carrito';
  }

  @override
  String get groceryReferences => 'Consultar reportes de precios en RD';

  @override
  String get groceryReferenceNote => 'Los reportes de Pro Consumidor son referencias fechadas. Revisa el producto, la presentación y la fecha; no son una cotización actual de tu tienda.';

  @override
  String get groceryReferenceError => 'No pudimos abrir los reportes de precios. Inténtalo de nuevo.';

  @override
  String get budgetPurpose => 'Gasto registrado + precios introducidos en esta lista. Marcar el carrito no registra un gasto.';

  @override
  String budgetShoppingOver(String amount) {
    return 'Con los precios conocidos te pasas $amount del presupuesto.';
  }

  @override
  String budgetAfterShopping(String amount) {
    return 'Te quedan $amount tras las compras con precio conocido.';
  }

  @override
  String get budgetIncomplete => 'Añade los precios que faltan antes de basarte en este estimado.';

  @override
  String get groceryReferenceTitle => 'Precios oficiales de referencia';

  @override
  String get groceryReferenceDisclaimer => 'Observaciones periódicas por tipo de supermercado, no cotizaciones en vivo. Revisa la presentación y el período antes de usar un estimado.';

  @override
  String get groceryReferenceSearch => 'Busca productos, por ejemplo arroz';

  @override
  String get groceryReferenceUnavailable => 'Las referencias no están disponibles ahora. Puedes introducir tu propio precio.';

  @override
  String get groceryUseReference => 'Toca para usar este estimado fechado';

  @override
  String get groceryReferenceAttribution => 'Fuente: Pro Consumidor / Datos Abiertos · ODbL 1.0';

  @override
  String get groceryReferencePrice => 'Estimado de referencia fechado, no un precio actual verificado de tu tienda.';

  @override
  String get groceryFindReference => 'Buscar un precio oficial de referencia';

  @override
  String get groceryEstimateNote => 'Basado en tus precios y las referencias fechadas que elegiste. El precio al pagar puede cambiar.';

  @override
  String get storeCompare => 'Comparar precios de supermercados';

  @override
  String get storeSearch => 'Buscar precios';

  @override
  String get storePriceSmartNote => 'PriceSmart: club Los Prados (6801), requiere membresía. Precios por empaque; pueden variar en otros clubes.';

  @override
  String get storeCompareNote => 'Precios del catálogo online por supermercado. Elige la marca y presentación exactas; productos distintos no son una comparación equivalente. Los precios, ofertas y existencias en tienda física pueden variar.';

  @override
  String get storeNearby => 'Ver tiendas cercanas';

  @override
  String get storeUnavailable => 'No hay precios en vivo disponibles para esta tienda. Puedes ver sus ubicaciones cercanas.';

  @override
  String get storeSearchHelp => 'Busca con al menos 2 caracteres. Los catálogos usan nombres de productos en español.';

  @override
  String get storeNoProducts => 'No encontramos productos coincidentes en este catálogo.';

  @override
  String storeObserved(String when) {
    return 'Consultado: $when';
  }

  @override
  String get storeUsePrice => 'Usar este producto y precio';

  @override
  String get storeViewProduct => 'Ver producto en el supermercado';

  @override
  String get storeOnlinePrice => 'Precio consultado en el catálogo online del supermercado. Revisa marca, presentación y fecha.';

  @override
  String get storeChooseItem => '¿Qué producto quieres comparar?';

  @override
  String get storeRefreshPrice => 'Actualizar precio';

  @override
  String get groceryEstimating => 'Estimando…';

  @override
  String get groceryEstimateUnavailable => 'Sin estimación';

  @override
  String get groceryAutoEstimate => 'Compra estimada: un empaque por cantidad. Revisa tamaño y marca.';

  @override
  String get groceryItemAdded => 'Producto añadido correctamente';

  @override
  String get budgetRecipeTitle => 'Platos para tu presupuesto';

  @override
  String get budgetRecipeCurrency => 'Los precios de recetas están en pesos dominicanos. Usa DOP para compararlos.';

  @override
  String budgetMealAllowance(Object amount) {
    return 'Objetivo por comida: $amount. Presupuesto restante dividido entre las comidas que quedan esta semana.';
  }

  @override
  String get budgetCostNote => 'Estimación de ingredientes consumidos, no de empaques completos. Cantidades de cocina y pesos de vegetales aproximados. Puede combinar tiendas; comprar todos los empaques puede costar más.';

  @override
  String get budgetNoConfirmedFit => 'Todavía no hay un plato con todos los precios que encaje en este objetivo. Revisa los costos o ajusta el presupuesto.';

  @override
  String budgetRecipeTotal(Object amount, Object servings) {
    return '≈ $amount para $servings porciones';
  }

  @override
  String budgetRecipePartial(Object count) {
    return 'Faltan precios o tamaños de empaque: $count ingredientes.';
  }

  @override
  String get budgetRecipeFits => 'Dentro de tu objetivo por comida';

  @override
  String get budgetRecipeOver => 'Supera tu objetivo por comida';

  @override
  String get budgetCostDetails => 'Costo por ingrediente';

  @override
  String get budgetPieces => 'unidades';

  @override
  String get budgetMealTarget => 'Presupuesto sugerido por comida';

  @override
  String get budgetTargetNote => 'Basado en tu presupuesto semanal restante.';

  @override
  String get budgetKnownSubtotal => 'Subtotal de ingredientes con precio · incompleto';

  @override
  String budgetPriceCoverage(Object priced, Object total) {
    return '$priced de $total ingredientes con precio';
  }

  @override
  String get budgetEstimateInfo => 'Cómo se calcula la estimación';

  @override
  String budgetPackPrice(Object amount) {
    return 'Empaque de referencia: $amount';
  }

  @override
  String get budgetRecipeEstimate => 'Total estimado de la receta';

  @override
  String get homeWeekEmpty => 'Tu semana está vacía. Añade tu primera comida para empezar a planificar.';

  @override
  String recipeNutrition(int calories, int protein, int carbs) {
    return '$calories kcal · ${protein}g proteínas · ${carbs}g carbohidratos';
  }

  @override
  String recipeCostPerServing(String amount) {
    return '≈ $amount por porción';
  }

  @override
  String recipePantryBreakdown(int total, int have, int missing) {
    return '$total ingredientes necesarios: $have en casa · $missing por comprar';
  }

  @override
  String get recipeAtHome => 'En casa';

  @override
  String get recipeToBuy => 'Por comprar';

  @override
  String recipeAddMissingToGroceries(int count) {
    return 'Añadir $count faltantes a la lista';
  }

  @override
  String get mealAddedSuccess => 'Comida añadida a tu plan ✓';

  @override
  String get planCopyDay => 'Copiar menú del día';

  @override
  String planCopyDayTo(String day) {
    return 'Copiar menú de $day a:';
  }

  @override
  String planCopySuccess(String day) {
    return 'Menú copiado a $day ✓';
  }

  @override
  String get groceryGenerateFromPlan => 'Generar desde el menú semanal';

  @override
  String groceryGeneratedCount(int count) {
    return 'Se agregaron $count ingredientes de tu plan semanal';
  }

  @override
  String get groceryNoPlannedMeals => 'No tienes comidas planificadas aún. Añade comidas para generar tu lista.';

  @override
  String get budgetThreeLimit => 'Presupuesto semanal: Cuánto quiero gastar';

  @override
  String get budgetThreeSpent => 'Gasto real: Cuánto he gastado realmente';

  @override
  String get budgetThreeEstimated => 'Costos estimados: Estimación de ingredientes';

  @override
  String get budgetDistinctionTip => 'El gasto real se mantiene separado de los costos estimados.';
}
