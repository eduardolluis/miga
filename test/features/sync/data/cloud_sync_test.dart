import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:miga/features/sync/data/cloud_sync.dart';
import 'package:miga/features/home/domain/home_details.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late CloudSync sync;
  Map<String, dynamic>? remote;
  var offline = false;
  Completer<void>? gate;
  var uploads = 0;
  const uid = '00000000-0000-4000-8000-000000000001';
  Map<String, dynamic> state(String name) => {
    'plan': {'2026-10-30:lunch': name},
    'home': const HomeDetails().toJson(),
  };

  Future<void> idle() async {
    await sync.sync().timeout(const Duration(seconds: 12));
    expect(sync.status, isNot(SyncStatus.syncing));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    remote = null;
    offline = false;
    gate = null;
    uploads = 0;
    client = SupabaseClient(
      'https://example.supabase.co',
      'public',
      postgrestOptions: const PostgrestClientOptions(retryEnabled: false),

      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        const headers = {'content-type': 'application/json'};
        if (request.url.path.startsWith('/auth/')) {
          return http.Response(
            jsonEncode({
              'access_token': 'token',
              'refresh_token': 'refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': uid,
                'aud': 'authenticated',
                'app_metadata': {},
                'user_metadata': {},
                'created_at': '2026-10-30T00:00:00Z',
              },
            }),
            200,
            headers: headers,
            request: request,
          );
        }
        if (offline) {
          return http.Response(
            '{"message":"Offline"}',
            503,
            headers: headers,
            request: request,
          );
        }
        if (request.url.path.endsWith('/rpc/miga_put_document')) {
          uploads++;
          final body = jsonDecode(request.body) as Map;
          final wait = gate;
          gate = null;
          if (wait != null) await wait.future;
          final revision = remote?['revision'] ?? 0;
          if (body['p_revision'] != revision) {
            return http.Response(
              '{"message":"Conflict","code":"40001"}',
              409,
              headers: headers,
              request: request,
            );
          }
          remote = {'data': body['p_data'], 'revision': (revision as int) + 1};
          return http.Response(
            '${remote!['revision']}',
            200,
            headers: headers,
            request: request,
          );
        }
        final singular =
            request.headers['accept']?.contains('vnd.pgrst.object') == true;
        return http.Response(
          jsonEncode(
            singular
                ? remote
                : remote == null
                ? []
                : [remote],
          ),
          200,
          headers: headers,
          request: request,
        );
      }),
    );
    await client.auth.signInWithPassword(
      email: 'test@example.com',
      password: 'test',
    );
    sync = CloudSync(client, uid);
    await sync.readState();
  });
  tearDown(() async {
    sync.dispose();
    await client.dispose();
  });

  test('Offline writes survive restart and upload without losing plan or preferences', () async {
    offline = true;
    await sync.write('state', state('Offline meal'));
    await idle();
    expect(sync.status, SyncStatus.pending);
    sync.dispose();
    sync = CloudSync(client, uid);
    expect(
      (await sync.readState())['plan']['2026-10-30:lunch'],
      'Offline meal',
    );
    offline = false;
    await sync.sync();
    expect(sync.status, SyncStatus.synced);
    expect(remote!['data']['plan']['2026-10-30:lunch'], 'Offline meal');
  });

  test(
    'A newer cloud revision causes conflict and keeps both versions intact',
    () async {
      remote = {'data': state('Other device'), 'revision': 2};
      await sync.write('state', state('This device'));
      await idle();
      expect(sync.status, SyncStatus.conflict);
      expect(remote!['data']['plan']['2026-10-30:lunch'], 'Other device');
      expect(
        (await sync.readState())['plan']['2026-10-30:lunch'],
        'This device',
      );
      await sync.resolve(keepLocal: false);
      expect(
        (await sync.readState())['plan']['2026-10-30:lunch'],
        'Other device',
      );
    },
  );

  test('Edits made while an upload is in flight remain dirty and are uploaded next', () async {
    final pending = Completer<void>();
    gate = pending;
    await sync.write('state', state('First'));
    for (var n = 0; n < 100 && uploads == 0; n++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    expect(uploads, 1);
    await sync.write('state', state('Second'));
    pending.complete();
    await idle();
    expect(uploads, 2);
    expect(remote!['data']['plan']['2026-10-30:lunch'], 'Second');
    expect((await sync.readState())['plan']['2026-10-30:lunch'], 'Second');
  });

  test('A fresh installation adopts cloud data instead of uploading an empty state', () async {
    remote = {'data': state('Cloud meal'), 'revision': 4};
    expect(await sync.sync(), isTrue);
    expect(uploads, 0);
    expect((await sync.readState())['plan']['2026-10-30:lunch'], 'Cloud meal');
  });
  test('A stale editor cannot overwrite cloud data before reload', () async {
    remote = {'data': state('Other device'), 'revision': 4};
    await sync.sync();
    expect(
      () => sync.writeState({
        '2026-10-30:lunch': 'Stale editor',
      }, const HomeDetails()),
      throwsStateError,
    );
    await sync.readState();
    await sync.writeState({
      '2026-10-30:lunch': 'Reviewed edit',
    }, const HomeDetails());
    await idle();
    expect(remote!['data']['plan']['2026-10-30:lunch'], 'Reviewed edit');
  });
}
