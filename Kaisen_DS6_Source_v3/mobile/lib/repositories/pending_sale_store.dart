import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PendingSaleStore {
  Future<String?> operationIdFor(String fingerprint);

  Future<void> save(String fingerprint, String operationId);

  Future<void> remove(String fingerprint);
}

class SharedPreferencesPendingSaleStore implements PendingSaleStore {
  static const _storageKey = 'kaisen.pending_sales.v1';

  @override
  Future<String?> operationIdFor(String fingerprint) async {
    final entries = await _readEntries();
    return entries[fingerprint];
  }

  @override
  Future<void> save(String fingerprint, String operationId) async {
    final preferences = await SharedPreferences.getInstance();
    final entries = await _readEntries(preferences);
    entries[fingerprint] = operationId;
    final saved = await preferences.setString(_storageKey, jsonEncode(entries));
    if (!saved) throw StateError('Pending sale could not be persisted.');
  }

  @override
  Future<void> remove(String fingerprint) async {
    final preferences = await SharedPreferences.getInstance();
    final entries = await _readEntries(preferences);
    entries.remove(fingerprint);

    final saved = entries.isEmpty
        ? await preferences.remove(_storageKey)
        : await preferences.setString(_storageKey, jsonEncode(entries));
    if (!saved) throw StateError('Pending sale could not be cleared.');
  }

  Future<Map<String, String>> _readEntries([
    SharedPreferences? preferences,
  ]) async {
    final store = preferences ?? await SharedPreferences.getInstance();
    final raw = store.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <String, String>{};

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw StateError('Pending sale storage is invalid.');
    }
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
}
