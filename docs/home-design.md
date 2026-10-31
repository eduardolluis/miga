# Home de Miga

El Home muestra propuestas de platos para el momento del día, con saludo personalizado y fotografías de estilo cotidiano. `AppShell` coordina navegación y editores; `HomeController` mantiene el reloj y el estado guardado. La estructura está explicada en [ARCHITECTURE.md](ARCHITECTURE.md).

## Saludo y horario

- El saludo utiliza el nombre de la cuenta (`given_name`, `full_name` o `name`); si no existe, toma la primera parte del correo. No se inventa un nombre cuando no hay cuenta.
- Las sugerencias usan la hora local del teléfono: desayuno de 05:00 a 10:59, almuerzo de 11:00 a 16:59 y cena de 17:00 a 04:59.
- El reloj se comprueba cada minuto y al volver del segundo plano. Al cambiar de día se actualiza la fecha seleccionada.
- El menú junto al título permite elegir otro momento del día. Esa selección manual se conserva hasta volver a «Según la hora actual».

## Carrusel y recetas

El catálogo local contiene nueve recetas bilingües, tres por cada comida. El carrusel muestra una receta completa por página, con swipe, indicadores, una foto propia, duración, porciones, acceso a la preparación y un botón para añadirla al plan. El presupuesto tiene su propio resumen debajo de la semana.

Cada receta tiene sus propios ingredientes y pasos. Los ingredientes se pueden marcar y añadir a la lista de compras. La planificación pide confirmación antes de guardar y utiliza la categoría de la receta, incluso si se abre desde el catálogo completo. Las recetas también se pueden buscar y filtrar en su pestaña.

No se calculan ni muestran macros, precios o estadísticas inventadas. La duración es una estimación orientativa de preparación; no se usa como dato nutricional.

## Semana y accesos

Los días tienen ancho y separación propios y se desplazan horizontalmente. El día seleccionado muestra la comida guardada para el momento elegido, con acceso a editarla. Plan muestra el calendario semanal completo.

El resumen de presupuesto y las tarjetas inferiores comparten márgenes, bordes y espaciado. Las tarjetas de compras y tiendas tienen igual tamaño cuando están en dos columnas y pasan a una columna con texto grande o pantalla estrecha.

Compras permite añadir, marcar y quitar productos. Tiendas abre una búsqueda de supermercados cercanos en mapas; no simula precios ni ubicaciones dentro de la app. El presupuesto, plan y lista permanecen guardados localmente por cuenta.

## Capturas actuales

Widgets de Flutter renderizados a 390 × 844 con fuentes e iconos reales y una cuenta de prueba:

- [Desayuno](previews/home-breakfast-v2.png).
- [Almuerzo](previews/home-lunch-v2.png).
- [Cena](previews/home-dinner-v2.png).
- [Semana, presupuesto y accesos](previews/home-overview-v2.png).

Las capturas sin el sufijo `v2` documentan la versión anterior.

## Fotografía y tipografía

Las nuevas imágenes tienen un tratamiento más suave, encuadres cotidianos y platos menos estilizados. Se generaron con la herramienta integrada `imagegen`; no son fotografías tomadas a usuarios. El archivo y el prompt están en [recipe-photography.md](recipe-photography.md).

Liberation Serif usa SIL Open Font License 1.1; aviso y licencia en [`assets/fonts/OFL.txt`](../assets/fonts/OFL.txt).
