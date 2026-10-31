import 'package:flutter/material.dart';
import 'package:miga/l10n/app_localizations.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final es = l.localeName == 'es';
    return Scaffold(
      appBar: AppBar(title: Text(l.privacyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              es
                  ? 'Información de privacidad de esta versión'
                  : 'Privacy information for this version',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              es
                  ? 'Miga utiliza tu correo e identificador de cuenta para iniciar sesión mediante Supabase, Google o Apple. Tus planes, compras, presupuestos, favoritas, despensa y preferencias alimentarias se guardan en el dispositivo, separados por cuenta. Las restricciones y alergias que introduzcas también forman parte de estas preferencias.'
                  : 'Miga uses your email and account identifier to sign in through Supabase, Google or Apple. Plans, groceries, budgets, favorites, pantry and dietary preferences are stored on this device, separately for each account. Any allergies or restrictions you enter are included in these preferences.',
            ),
            const SizedBox(height: 20),
            Text(
              es
                  ? 'Si la sincronización está configurada, esos datos se copian a tu cuenta de Supabase. Las listas compartidas pueden ser vistas y editadas por las personas que se unan mediante su invitación. No compartas el código fuera de tu hogar.'
                  : 'When cloud sync is configured, this data is copied to your Supabase account. Shared lists can be viewed and edited by people who join using their invitation. Keep invitation codes within your household.',
            ),
            const SizedBox(height: 20),
            Text(
              es
                  ? 'Las búsquedas de precios envían el nombre del producto a los supermercados consultados. Abrir mapas o un comercio utiliza el servicio externo correspondiente. No añadimos publicidad ni analítica de seguimiento a esta versión. Las compras de suscripciones, cuando estén habilitadas, las procesan Apple o Google; Miga no recibe los datos de tu tarjeta.'
                  : 'Price searches send the product name to the stores being searched. Opening maps or a store uses that external service. This version adds no advertising or tracking analytics. When subscriptions are enabled, Apple or Google processes payments; Miga does not receive your card details.',
            ),
            const SizedBox(height: 20),
            Text(
              es
                  ? 'Puedes modificar tus preferencias y borrar productos o planes desde la app. Eliminar tu cuenta desde Perfil borra los datos de la cuenta y las copias de esta instalación. Las listas compartidas que hayas creado también se eliminan. Eliminar la cuenta no cancela una suscripción: debes gestionarla en la tienda. Antes de usar un dispositivo compartido, ten en cuenta que tus datos locales permanecen guardados al cerrar sesión para permitir trabajar sin conexión.'
                  : 'You can change preferences and delete products or plans in the app. Deleting your account from Profile removes account data and the copies on this installation. Shared lists you own are also deleted. Deleting an account does not cancel a subscription; manage it in the store. On a shared device, remember that local data remains after sign-out to support offline use.',
            ),
            const SizedBox(height: 20),
            const Text(
              String.fromEnvironment(
                'MIGA_PRIVACY_CONTACT',
                defaultValue: 'Miga · versión de prueba / test version',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
