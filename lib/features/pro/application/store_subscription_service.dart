import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreSubscriptionService extends ChangeNotifier {
  StoreSubscriptionService(this.client);
  final SupabaseClient client;
  static const enabled = bool.fromEnvironment('MIGA_BILLING_ENABLED');
  static const _productNames = String.fromEnvironment('MIGA_STORE_PRODUCTS');
  List<ProductDetails> products = [];
  bool available = false, busy = false, failed = false;
  DateTime? expiresAt;
  Timer? _expiryTimer;
  bool get active => expiresAt?.isAfter(DateTime.now()) == true;
  bool _disposed = false;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _processing = <String>{};

  Future<void> initialize() async {
    if (!enabled || _productNames.trim().isEmpty || kIsWeb) return;
    try {
      _subscription ??= InAppPurchase.instance.purchaseStream.listen(
        _purchases,
        onError: (_) {
          failed = true;
          busy = false;
          _notify();
        },
      );
      available = await InAppPurchase.instance.isAvailable();
      if (!available) return;
      final response = await InAppPurchase.instance.queryProductDetails(
        _productNames
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet(),
      );
      products = response.productDetails;
      failed = response.error != null;
      await refreshEntitlement();
    } catch (_) {
      failed = true;
      available = false;
    } finally {
      _notify();
    }
  }

  Future<void> refreshEntitlement() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null || !enabled) return;
    try {
      final row = await client
          .from('miga_entitlements')
          .select('expires_at')
          .eq('user_id', uid)
          .maybeSingle();
      expiresAt = row == null
          ? null
          : DateTime.tryParse(row['expires_at'] as String);
      _expiryTimer?.cancel();
      if (expiresAt?.isAfter(DateTime.now()) == true) {
        _expiryTimer = Timer(expiresAt!.difference(DateTime.now()), _notify);
      }
    } catch (_) {
      failed = true;
    }
    _notify();
  }

  Future<void> buy(ProductDetails product) async {
    if (busy || !available || !enabled || !products.contains(product)) return;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    busy = true;
    failed = false;
    _notify();
    try {
      final launched = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: uid,
        ),
      );
      if (!launched) {
        busy = false;
        failed = true;
      }
    } catch (_) {
      busy = false;
      failed = true;
    }
    _notify();
  }

  Future<void> restore() async {
    if (busy || !available || !enabled) return;
    busy = true;
    failed = false;
    _notify();
    try {
      await InAppPurchase.instance.restorePurchases(
        applicationUserName: client.auth.currentUser?.id,
      );
    } catch (_) {
      failed = true;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _purchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (_disposed) return;
      final key = '${purchase.productID}:${purchase.purchaseID}';
      if (!_processing.add(key)) continue;
      try {
        if (purchase.status == PurchaseStatus.pending) {
          busy = true;
          continue;
        }
        if (purchase.status == PurchaseStatus.error ||
            purchase.status == PurchaseStatus.canceled) {
          busy = false;
          failed = purchase.status == PurchaseStatus.error;
          continue;
        }
        if (purchase.status != PurchaseStatus.purchased &&
            purchase.status != PurchaseStatus.restored) {
          continue;
        }
        // The client never grants access based on a local purchase event.
        final response = await client.functions.invoke(
          'verify-purchase',
          body: {
            'productId': purchase.productID,
            'purchaseId': purchase.purchaseID,
            'source': purchase.verificationData.source,
            'verificationData':
                purchase.verificationData.serverVerificationData,
          },
        );
        if (response.status != 200 ||
            response.data is! Map ||
            response.data['verified'] != true) {
          failed = true;
          busy = false;
          continue;
        }
        await refreshEntitlement();
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
        busy = false;
      } catch (_) {
        // Leave unverified purchases pending for a later restore/retry.
        failed = true;
        busy = false;
      } finally {
        _processing.remove(key);
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _expiryTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
