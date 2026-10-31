# Miga — revisión y mejoras integradas

**Fecha:** 31 de octubre de 2026. **Base:** ZIP `miga.zip` facilitado por el propietario.

## No modificamos la identidad visual

Se mantienen las pantallas, componentes visuales, paleta crema/verde oliva, logos,
carátulas de recetas, navegación, iconos y tipografía existente. Las únicas
adaptaciones visibles son opciones adicionales de país/moneda y la explicación
del cálculo de presupuesto sugerido.

## Cambios de código incluidos

| Archivo | Qué cambia y por qué |
|---|---|
| `lib/features/recipes/domain/ingredient_dietary_tags.dart` | **Nuevo:** clasificación explícita de carne, pescado, lácteos, huevo, gluten y frutos secos; trata de forma conservadora alimentos de composición variable (avena, granola, leche no especificada). |
| `lib/features/profile/domain/household_preferences.dart` | Aplica restricciones a los ingredientes de recetas y cantidades; mantiene desagrados; conserva compatibilidad JSON y acepta otros países/monedas. |
| `lib/core/region/supported_regions.dart` | **Nuevo:** registro único de países, códigos ISO, monedas y símbolos. |
| `lib/features/profile/presentation/preferences_sheet.dart` | Seis países y sus monedas; cambiar país propone su moneda de manera visible. |
| `lib/features/budget/domain/weekly_budget.dart` | Importes con símbolo correspondiente, sin conversiones falsas. |
| `lib/features/budget/presentation/sheets/budget_editor_sheet.dart` | Selector de las seis monedas. |
| `lib/features/groceries/domain/grocery_item.dart` | Importe por moneda, precios negativos inválidos y totales proyectados que pueden excluir productos ya comprados. |
| `lib/features/groceries/presentation/sheets/grocery_price_editor.dart` | Admite moneda manual en la lista. |
| `lib/features/home/application/home_controller.dart` | Acepta presupuestos en las monedas soportadas; mantiene estimaciones de supermercados limitadas a DO/DOP. |
| `lib/features/home/presentation/widgets/home_budget_summary.dart` | **Corrige posible doble conteo**: productos marcados como comprados ya no aparecen como gastos de compra pendientes en la proyección de Home. |
| `lib/features/budget/application/recipe_cost_estimator.dart` | Expone `remainingMealSlots` y protege contra presupuestos agotados, división por cero y valores no finitos. |
| `lib/features/home/presentation/widgets/budget_recipe_suggestions.dart` | Muestra la operación usada para el objetivo por comida. |

### Pruebas nuevas y ampliadas

- `test/features/profile/domain/household_preferences_test.dart`: vegetarianismo,
  veganismo, restricciones múltiples, ingredientes inciertos, lectura de datos antiguos,
  países nuevos.
- `test/features/recipes/domain/ingredient_dietary_tags_test.dart`: cobertura de
  clasificación y casos conservadores.
- `test/core/region/supported_regions_test.dart`: países, monedas y formateo.
- `test/features/groceries/domain/grocery_item_test.dart`: exclusión de productos
  comprados, precios inválidos.
- `test/features/budget/application/recipe_cost_estimator_test.dart`: cantidad
  de comidas restantes.

## Arquitectura (dónde trabajar)

```text
lib/
  app/                    # Inicialización y navegación (sin cambios visuales)
  core/
    theme/                # Identidad original de Miga (sin cambios)
    region/               # NUEVO: países y monedas
  features/
    recipes/
      domain/             # Modelo + etiquetas de ingredientes
      data/               # Catálogo fijo actual
      presentation/       # UI original
    profile/
      domain/             # Preferencias y filtros
      presentation/       # Hoja para editar preferencias
    budget/
      application/        # Cálculos
      domain/             # Presupuesto
      presentation/       # UI original + fórmula
    groceries/
      application/        # Agregar recetas/stock al carrito (ya existía)
      domain/             # Precios, cantidades y subtotales
    home/
      application/        # Estado y acciones (ya existía)
      presentation/       # UI original + total pendiente correcto
    sync/                 # Sincronización con Supabase (ya existía)
    pro/                  # Suscripción (ya existía, no se activa)
  l10n/                   # Idiomas preexistentes
supabase/
  migrations/             # Esquema/RLS existente
  functions/              # Verificación del servidor existente
  tests/                  # Pruebas de acceso existentes
test/                     # Pruebas Flutter
```

## Importante: qué NO es seguro afirmar ni activar todavía

- **Alergias:** los filtros son ayudas para descubrir recetas, NO certificaciones
  de ausencia de alérgenos. La leche puede ser vegetal o de vaca; avena,
  granola y alimentos procesados pueden contener alérgenos. Se deben comprobar
  envases, sustituciones y contaminación cruzada antes de cocinar.
- **Precios:** las consultas automáticas a supermercados siguen disponibles
  únicamente para República Dominicana y DOP. Otros países y monedas permiten
  introducir precios **manualmente**; NO existe conversión automática ni
  fuentes verificadas de supermercados extranjeros.
- **Recetas:** sigue existiendo el catálogo integrado de nueve recetas.
  Agregar recetas de un servidor externo con metadatos verificados, imágenes,
  cantidades y un proceso editorial requiere una siguiente fase y esquema de datos.
- **Supabase:** el esquema y las políticas preexistentes requieren despliegue
  en tu proyecto de Supabase. La validación local de políticas SQL **sí** se
  ejecutó en esta entrega (13 comprobaciones correctas).
- **iOS/Android:** no se ejecutó `flutter analyze`, `flutter test` ni una compilación
  de dispositivos en este entorno, porque Flutter no está instalado. Se agregaron
  pruebas para que las ejecutes en tu máquina.
- **Google/Apple login, Miga Pro, precios reales y sincronización multidispositivo:**
  la implementación existente depende de credenciales, tiendas, API y pruebas
  con cuentas y dispositivos reales. No activamos cobros.

## Aplicar sin perder tu proyecto

El ZIP de **cambios** solo contiene archivos nuevos o modificados. No incluye
archivos `.env`, secretos, dependencias instaladas, imágenes originales ni
fuentes. Mantén una copia de tu proyecto y extrae los cambios **encima** de
la carpeta `miga` actual. No borres tu carpeta original ni sus recursos:
los archivos no incluidos se conservan intactos.

Desde la carpeta que **contiene** `miga/`:

```bash
cp -a miga miga_backup
unzip -o Miga_actualizaciones.zip
cd miga
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Antes de usar en producción, prueba manualmente: cambiar países/monedas,
cambiar porciones, preferencias vegetarianas y alergias, guardar presupuestos,
comprar/marcar productos, entrar/salir con Google/Apple, sincronizar dos equipos
y trabajar offline. Confirma SQL de Supabase instalado, fuentes de precios y
configuraciones de cada servicio.
