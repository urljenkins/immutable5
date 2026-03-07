import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageProvider {
  final FlutterSecureStorage _storage;
  static SecureStorageProvider? _instance;

  factory SecureStorageProvider({FlutterSecureStorage? storage}) {
    if (storage != null) {
      return SecureStorageProvider._internal(storage: storage);
    }
    return _instance ??= SecureStorageProvider._internal();
  }

  SecureStorageProvider._internal({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<int?> getInt(String key) async {
    final str = await _storage.read(key: key);
    if (str == null) return null;
    return int.tryParse(str);
  }

  Future<void> setInt(String key, int value) async {
    await _storage.write(key: key, value: value.toString());
  }

  Future<double?> getDouble(String key) async {
    final str = await _storage.read(key: key);
    if (str == null) return null;
    return double.tryParse(str);
  }

  Future<void> setDouble(String key, double value) async {
    await _storage.write(key: key, value: value.toString());
  }

  Future<bool?> getBool(String key) async {
    final str = await _storage.read(key: key);
    if (str == null) return null;
    return str == 'true';
  }

  Future<void> setBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  Future<List<String>?> getStringList(String key) async {
    final str = await _storage.read(key: key);
    if (str == null) return null;
    try {
      final decoded = json.decode(str);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _storage.write(key: key, value: json.encode(value));
  }

  Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }

  Future<Set<String>> getKeys() async {
    final all = await _storage.readAll();
    return all.keys.toSet();
  }

  Future<dynamic> get(String key) async {
    return await _storage.read(key: key);
  }
}
