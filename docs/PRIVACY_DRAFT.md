# Borrador de privacidad de Miga — completar antes de publicar

Responsable: **[NOMBRE LEGAL]**. Contacto: **[CORREO O URL DE SOPORTE]**.
Fecha de vigencia: **[FECHA DE PUBLICACIÓN]**. Política pública: **[URL HTTPS]**.
Estos campos y la revisión correspondiente son requisitos pendientes de lanzamiento.

Miga permite planificar comidas, llevar una despensa, preparar compras y registrar
presupuestos. Utiliza correo e identificador de cuenta para autenticar mediante
Supabase, Google o Apple. El usuario puede introducir comidas, presupuesto y gasto
real, productos, favoritas, cantidades, integrantes del hogar, país, moneda, idioma,
restricciones alimentarias y alimentos excluidos. Las alergias/restricciones que
se introduzcan forman parte de esos datos.

Los datos se guardan localmente, separados por cuenta, para trabajar sin conexión.
Cuando la sincronización está configurada se copian al proyecto de Supabase de Miga.
Cerrar sesión conserva la copia local para permitir volver a trabajar sin conexión.
En un dispositivo compartido deben tenerse en cuenta las protecciones y copias de
seguridad del propio sistema operativo.

Las listas compartidas son visibles y editables por sus integrantes. Las invitaciones
permiten unirse a una lista concreta y deben compartirse solo con las personas
previstas. Al eliminar una cuenta también se eliminan las listas que esa cuenta
posea; los miembros pierden acceso a esas listas.

Las búsquedas de precios transmiten términos de productos a los supermercados
consultados. Mapas y páginas de comercios se abren en servicios externos. Esta
implementación no añade publicidad ni SDK de seguimiento analítico. Deben revisarse
las prácticas finales de los proveedores y cualquier SDK que se añada después.

Las suscripciones, cuando se habiliten, se tramitan con Apple o Google. Miga verifica
el identificador de compra, cuenta vinculada, producto y vigencia en el servidor;
no recibe los datos de la tarjeta. Los tokens de verificación se guardan con acceso
restringido al servidor y se eliminan con la cuenta. Cancelar una suscripción se
gestiona en la tienda; borrar una cuenta no cancela automáticamente esa suscripción.

El usuario puede modificar preferencias, eliminar comidas/productos y solicitar
el borrado de cuenta desde Perfil. El borrado del servidor elimina los datos de la
cuenta y sus listas propias. La app borra la copia local de esa instalación tras
confirmar el borrado del servidor. Otras instalaciones sin conexión y copias de
seguridad del sistema pueden conservar copias hasta que se eliminen o actualicen.

Antes de publicar, el responsable debe completar: finalidad y base jurídica
aplicables, conservación y tratamiento de copias/respaldos de proveedores, países
de alojamiento/transferencias, procedimiento de derechos y contacto, política
respecto a menores, términos de suscripción y declaraciones de datos de cada tienda.
Este borrador describe el código de esta versión y requiere revisión de la práctica
real del servicio.
