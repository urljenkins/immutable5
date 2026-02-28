import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageProvider {
  static final SecureStorageProvider _instance =
      SecureStorageProvider._internal();
  factory SecureStorageProvider() => _instance;

  SecureStorageProvider._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> initMigration() async {
    final migrated = await _storage.read(key: 'has_migrated_from_prefs');
    if (migrated == 'true') return;

    final oldPrefs = await SharedPreferences.getInstance();
    final keys = oldPrefs.getKeys();

    for (final key in keys) {
      final val = oldPrefs.get(key);
      if (val != null) {
        await _storage.write(key: key, value: val.toString());
      }
    }
    await _storage.write(key: 'has_migrated_from_prefs', value: 'true');
    await oldPrefs.clear();
  }

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

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
