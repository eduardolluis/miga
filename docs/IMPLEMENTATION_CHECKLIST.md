# Implementación del checklist de Miga

Se conserva la identidad crema y verde. Esta lista distingue código implementado
de servicios y pruebas reales que todavía necesitan configuración externa.

## Home, recetas y preferencias

- [x] Presupuesto restante y las tres comidas de hoy.
- [x] Encabezado compacto y planificación desde el carrusel sin reescribir nombres.
- [x] Recomendaciones que respetan restricciones y alimentos excluidos, priorizan
  despensa/favoritas y comparan costos completos con el presupuesto restante.
- [x] Filtros rápidos (hasta 20 minutos), proteínas (25 g o más por porción),
  presupuesto, ingredientes y favoritas.
- [x] Porciones de 1 a 24, cantidades físicas y costos recalculados; nutrición
  aproximada por porción y total para las porciones seleccionadas.
- [x] Ingredientes disponibles/faltantes y compras de las cantidades faltantes.
- [x] Favoritas y porciones preferidas persistentes por cuenta.
- [x] Verificadas visualmente las nueve fotos del atlas y sus recetas.
- [x] País DO/US, DOP/USD, idioma del dispositivo/es/en, tamaño del hogar,
  restricciones y alimentos excluidos, editables desde Perfil.

Las cantidades de las recetas son estimaciones de cocina. Las cifras nutricionales
del catálogo son aproximadas por porción y no proceden de un análisis de laboratorio.
Cambiar el tamaño del hogar afecta las recetas nuevas; las comidas ya planificadas
conservan sus porciones explícitas y pueden editarse individualmente.

## Plan, despensa y compras

- [x] IDs de recetas y porciones en el plan, compatibles con comidas v1 de texto.
- [x] Elegir receta, editar, borrar, mover, copiar día y repetir en varios días.
- [x] Costos por día y semana, cobertura incompleta visible, actualización al editar.
- [x] Despensa con gramos, mililitros o unidades, guardada por cuenta.
- [x] Agrupar ingredientes repetidos, sumar cantidades y descontar stock una vez.
- [x] Generación y sincronización opcional con el plan; mantener productos manuales,
  precios, cantidades ajustadas y marcas de compra.
- [x] Conversión de cantidades necesarias a empaques cuando la referencia permite
  conocer su tamaño y unidad. Las bases desconocidas se muestran sin total confirmado.
- [x] Edición de precios y cantidades; gasto real separado de estimaciones.
- [x] Vista previa del plan automático para los horarios restantes de la semana.
  Conserva comidas existentes y solo añade recetas con precios completos que caben
  en el presupuesto disponible. No promete un menú completo si faltan datos.
- [x] Alternativas de recetas más económicas, con iguales porciones y respetando
  preferencias; confirmación antes de reemplazar.
- [x] Historial de presupuestos y gastos reales semanales.

## Experiencia y persistencia

- [x] Estados de carga/error/vacío, guardados confirmados y deshacer último cambio.
- [x] Protección frente a envíos duplicados y conservación del estado entre pestañas.
- [x] Comprobaciones de pantallas pequeñas, orientación e idiomas con texto ampliado.
- [x] Referencias editables por kg/litro/unidad, precios sin conocer identificados,
  fecha/comercio de ofertas y ningún cambio de moneda implícito.
- [x] Código de sincronización con copia local duradera, reintentos y revisiones CAS.
- [x] Plan y hogar se guardan como un solo documento para evitar estados partidos.
- [x] Conflictos entre dispositivos requieren elegir una versión; los borradores
  de listas compartidas se conservan localmente durante errores.
- [x] Migración de Supabase con RLS y funciones para listas compartidas/invitaciones.
- [x] Función autenticada de eliminación de cuenta, con cascadas de datos.

Los precios automáticos actuales corresponden a supermercados dominicanos y DOP.
Otros países/monedas utilizan precios introducidos por el usuario. Un subtotal
incompleto nunca se trata como un presupuesto confirmado ni se convierte entre monedas.

## Gratis y Pro

- [x] Gratis: catálogo, favoritas, hogar/despensa, plan manual, compras, presupuesto,
  referencias editables e historial básico.
- [x] Herramientas Pro en beta gratuita mientras los cobros estén desactivados:
  planificación automática, sustituciones económicas y listas compartidas.
- [x] Integración de compra/restauración con `in_app_purchase` y gestión en la tienda.
- [x] Verificación exclusivamente en servidor: Apple valida firmas/cadena/entorno,
  cuenta y estado de la suscripción; Google consulta Subscriptions V2 y vinculación
  a la cuenta. El cliente no puede concederse Pro.
- [x] Vigencia, cancelación al final del período, revocaciones y restauraciones
  contempladas por el verificador; trabajo de actualización de suscripciones.
- [x] Cobros desactivados por defecto; no se inventan IDs de productos ni precios.
- [ ] Crear productos reales, configurar secretos, términos/privacidad y probar
  compra, cancelación, restauración, vencimiento y reembolso en ambas tiendas.

## Activación y lanzamiento pendientes

- [ ] Conectar el proyecto real de Supabase y aplicar la migración revisada.
- [ ] Desplegar funciones y verificar sincronización entre dos cuentas/dispositivos
  reales, incluyendo una sesión sin conexión y conflictos.
- [ ] Habilitar Sign in with Apple para el Bundle ID y proveedor de Supabase;
  probar Apple/Google/OTP, cancelación y reintentos con credenciales reales.
- [ ] Ejecutar en simulador iPhone y dispositivo Android; las pruebas de widgets
  y compilación de CI no sustituyen las pruebas con proveedores/dispositivos reales.
- [ ] Medir desplazamiento, memoria y búsqueda de precios en un teléfono antiguo.
- [ ] Completar responsable/contacto/URLs y revisión de privacidad; completar
  declaraciones de datos de App Store y Google Play antes de publicar.
- [ ] Configurar y comprobar borrado real de cuenta antes de habilitarlo en producción.

Instrucciones reproducibles: [configuración de servicios](SERVICES_SETUP.md).
La automatización de CI verifica Dart, pruebas, SQL/RLS, funciones y compilaciones
Android/iOS; no despliega ni modifica el proyecto de Supabase.
