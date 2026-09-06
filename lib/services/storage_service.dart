import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_menu/clients/api_client.dart';

class StorageService {
  static const String _menuIdKey = 'menu-id';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> getMenuId() async {
    String? menuId = await _storage.read(key: _menuIdKey);
    return menuId ?? await _generateAndSaveMenuId();
  }

  Future<String> _generateAndSaveMenuId() async {
    var client = ApiClient();
    String menuId = await client.fetchMenuId();
    await _storage.write(key: _menuIdKey, value: menuId);
    return menuId;
  }
}