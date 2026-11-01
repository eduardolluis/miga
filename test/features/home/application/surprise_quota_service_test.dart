import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/features/home/application/surprise_quota_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Guest free allowance lasts exactly three uses and persists', () async {
    final service = SurpriseQuotaService();
    expect((await service.remaining()).remaining, 3);
    expect((await service.consume()).remaining, 2);
    expect((await service.consume()).remaining, 1);
    expect((await service.consume()).remaining, 0);
    final exhausted = await SurpriseQuotaService().consume();
    expect(exhausted.allowed, false);
    expect(exhausted.remaining, 0);
  });

  test('RPC allowance is validated, including Pro status', () {
    final pro = SurpriseAllowance.fromRpc({
      'allowed': true,
      'remaining': 3,
      'pro': true,
    });
    expect(pro.isPro, true);
    expect(
      SurpriseAllowance.fromRpc({
        'allowed': false,
        'remaining': 0,
        'pro': false,
      }).allowed,
      false,
    );
    expect(
      () => SurpriseAllowance.fromRpc({'remaining': 3}),
      throwsFormatException,
    );
  });
}
