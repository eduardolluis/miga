import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:miga/app/miga_app.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/auth/data/supabase_auth_service.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _MigaBootstrap());
}

/// Uses the same logo typography and colors as Home; no fake loading delay.
class _MigaBootstrap extends StatefulWidget {
  const _MigaBootstrap();
  @override
  State<_MigaBootstrap> createState() => _MigaBootstrapState();
}

class _MigaBootstrapState extends State<_MigaBootstrap> {
  late Future<SupabaseClient> _loading = _initialize();

  Future<SupabaseClient> _initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    return Supabase.instance.client;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<SupabaseClient>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final client = snapshot.data!;
        return MigaApp(
          authService: SupabaseAuthService(client),
          client: client,
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Miga',
                      key: ValueKey('miga-splash-logo'),
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (!snapshot.hasError)
                      const SizedBox(
                        width: 178,
                        child: LinearProgressIndicator(
                          key: ValueKey('miga-startup-progress'),
                          minHeight: 5,
                          backgroundColor: Color(0xFFDCE6D2),
                          color: AppColors.olive,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      )
                    else ...[
                      const Text(
                        'Could not start Miga. Check your connection and configuration.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(() { _loading = _initialize(); }),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
