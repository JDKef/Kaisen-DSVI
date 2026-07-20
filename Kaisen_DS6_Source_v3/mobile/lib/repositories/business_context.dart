import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class BusinessContext {
  Future<String> currentBusinessId();
}

class SupabaseBusinessContext implements BusinessContext {
  SupabaseBusinessContext({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;
  String? _cachedUserId;
  String? _cachedBusinessId;

  SupabaseClient get _client =>
      _clientOverride ?? Supabase.instance.client;

  @override
  Future<String> currentBusinessId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Authentication required.');
    }

    if (_cachedUserId == userId && _cachedBusinessId != null) {
      return _cachedBusinessId!;
    }

    final row = await _client
        .from('business_members')
        .select('business_id')
        .eq('user_id', userId)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    if (row == null || row['business_id'] == null) {
      throw StateError('Authenticated business membership was not found.');
    }

    _cachedUserId = userId;
    _cachedBusinessId = row['business_id'].toString();
    return _cachedBusinessId!;
  }
}
