import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    // Legacy photos are migration inputs/test fixtures, excluded from the app
    // bundle. Tests can still exercise their dimensions and image rendering.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) {
          if (message == null) return null;
          final key = utf8.decode(message.buffer.asUint8List());
          final fixture =
              key.startsWith('assets/images/recipes/v2/') &&
              !key.contains('..');
          final file = File(
            fixture ? key : '${Platform.environment['UNIT_TEST_ASSETS']}/$key',
          );
          if (!file.existsSync()) return null;
          return SynchronousFuture<ByteData>(
            file.readAsBytesSync().buffer.asByteData(),
          );
        });
  });
  await testMain();
}
