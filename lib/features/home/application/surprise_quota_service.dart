import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-tracked free allowance for signed-in accounts. The guest demo uses
/// device-local storage and is not a substitute for account-level enforcement.
class SurpriseAllowance {
  const SurpriseAllowance({
    required this.allowed,
    required this.remaining,
    this.isPro = false,
  });

  final bool allowed;
  final int remaining;
  final bool isPro;

  factory SurpriseAllowance.fromRpc(dynamic response) {
    if (response is! Map) {
      throw const FormatException('Invalid surprise allowance response');
    }
    final data = Map<String, dynamic>.from(response);
    if (data['allowed'] is! bool ||
        data['pro'] is! bool ||
        data['remaining'] is! num) {
      throw const FormatException('Incomplete surprise allowance response');
    }
    return SurpriseAllowance(
      allowed: data['allowed'] as bool,
      isPro: data['pro'] as bool,
      remaining: ((data['remaining'] as num).toInt()).clamp(0, 3),
    );
  }
}

class SurpriseQuotaService {
  SurpriseQuotaService({
    this.client,
    this.guestKey = 'miga_surprise_guest_used',
  });

  final SupabaseClient? client;
  final String guestKey;

  bool get _signedIn => client?.auth.currentUser != null;

  Future<SurpriseAllowance> remaining() async {
    if (_signedIn) {
      return SurpriseAllowance.fromRpc(
        await client!.rpc('miga_surprise_remaining'),
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final remaining = (3 - (prefs.getInt(guestKey) ?? 0)).clamp(0, 3);
    return SurpriseAllowance(allowed: remaining > 0, remaining: remaining);
  }

  Future<SurpriseAllowance> consume() async {
    if (_signedIn) {
      // Never fall back to local credits after a server error for an account.
      return SurpriseAllowance.fromRpc(
        await client!.rpc('miga_consume_surprise'),
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final used = (prefs.getInt(guestKey) ?? 0).clamp(0, 3);
    if (used >= 3) {
      return const SurpriseAllowance(allowed: false, remaining: 0);
    }
    await prefs.setInt(guestKey, used + 1);
    return SurpriseAllowance(allowed: true, remaining: 2 - used);
  }
}
