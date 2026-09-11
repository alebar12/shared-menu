import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String _menuIdKey = 'menu-id';
  static const String _menuSecretKey = 'menu-secret';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getMenuId() {
    return _storage.read(key: _menuIdKey);
  }

  Future<void> saveMenuId(String menuId) {
    return _storage.write(key: _menuIdKey, value: menuId);
  }

  Future<String?> getMenuSecret() {
    return _storage.read(key: _menuSecretKey);
  }

  Future<void> saveMenuSecret(String secret) {
    return _storage.write(key: _menuSecretKey, value: secret);
  }
}
