# Home de Miga

La pantalla usa crema, oliva, titulares con Liberation Serif y fotografías con controles nativos de Flutter. Los componentes y el estado se mantienen separados; `HomeScreen` coordina las rutas y los editores, y `HomeController` maneja el plan y el guardado.

## Comportamiento

- **Inicio:** resumen con un carrusel de una tarjeta completa por página (`viewportFraction: 1`), swipe e indicadores accesibles. Las páginas de comida y presupuesto comparten altura y se adaptan al texto ampliado.
- **Comidas:** desayuno, almuerzo y cena seleccionables. La tira semanal marca los días con comidas. Elegir un día actualiza el hero y vuelve a la primera página del carrusel.
- **Plan:** calendario de la semana completa con las tres comidas de cada día. Se pueden añadir, editar y quitar comidas.
- **Presupuesto:** límite y gasto registrados manualmente, por semana, en DOP o USD. Los importes siempre aparecen sobre un fondo sólido.
- **Compras:** un único acceso desde Inicio. La lista permite añadir, marcar y eliminar productos, con guardado explícito.
- **Recetas:** una receta inicial de salmón con ingredientes, preparación y confirmación antes de añadirla al día y comida seleccionados. Las comidas escritas a mano usan un fondo neutro para no atribuirles una foto incorrecta.
- **Perfil:** datos de la cuenta, acceso al presupuesto y cierre de sesión.

Un usuario nuevo comienza sin comidas, presupuesto ni productos. No se precargan estadísticas de ejemplo en la aplicación. Los datos se guardan localmente por cuenta y se recuperan después de abrir de nuevo la pantalla. La lista de compras no se genera automáticamente desde las recetas.

La generación de planes con IA, las ubicaciones/precios de tiendas, la sincronización entre dispositivos y las funciones premium quedan pendientes. Tiendas muestra un estado vacío. No hay promoción permanente de Pro, macros inventados ni indicadores de actividad simulados.

## Capturas

Renderizadas desde los widgets de Flutter a 390 × 844, con las fuentes e iconos reales:

- [Primer día](previews/home-empty.png).
- [Con comidas planificadas](previews/home-planned.png).
- [Presupuesto](previews/home-budget.png).

Las dos últimas capturas usan datos de prueba exclusivamente para la revisión visual.

## Recursos

- Foto generada: [`assets/images/home/lemon-salmon.png`](../assets/images/home/lemon-salmon.png).
- Herramienta: `imagegen`, herramienta integrada, modo de generación de imagen nueva.
- Fuente: Liberation Serif, SIL Open Font License 1.1; aviso y licencia en [`assets/fonts/OFL.txt`](../assets/fonts/OFL.txt).
- Las fotografías de lista de compras y tiendas reutilizan los recursos de onboarding.

Prompt de la fotografía:

> Use case: photorealistic-natural. Asset type: food photography background for a mobile meal-planning app hero card. Primary request: a freshly cooked salmon fillet with lemon slices and herbs, roasted baby potatoes and green vegetables, on a rustic ivory ceramic plate. Natural warm window light, quiet Mediterranean kitchen, linen and wood, rich olive greens and warm cream palette. Close editorial food photograph at a 45 degree angle, plate centered, composition suitable for cropping to a vertical rounded rectangle; food fills central two thirds with a little breathing room at top and bottom for app overlays. Real appetizing texture, refined restrained food magazine photography. No writing, no UI, no logos, no watermark. Create just the food photograph, not an app mockup.
