import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'services/auth_service.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final uri = Uri.tryParse(supabaseUrl);
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      supabasePublishableKey.trim().isEmpty) {
    throw StateError(
      'Missing or invalid Supabase configuration. Start with the Miga launch '
      'configuration in VS Code, or run '
      'flutter run --dart-define-from-file=supabase.env.json',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(MigaApp(authService: SupabaseAuthService(Supabase.instance.client)));
}
