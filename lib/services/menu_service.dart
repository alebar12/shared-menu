import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/services/storage_service.dart';

class MenuService {
  MenuService({
    required ApiClient apiClient,
    required StorageService storageService,
  })  : _apiClient = apiClient,
        _storageService = storageService;

  final ApiClient _apiClient;
  final StorageService _storageService;

  Future<String>? _menuIdFuture;

  Future<String> currentMenuId() async {
    _menuIdFuture ??= _readOrCreateMenuId();
    try {
      return await _menuIdFuture!;
    } catch (_) {
      _menuIdFuture = null;
      rethrow;
    }
  }

  Future<String> _readOrCreateMenuId() async {
    final existing = await _storageService.getMenuId();
    if (existing != null) {
      return existing;
    }
    final menuId = await _apiClient.fetchMenuId();
    await _storageService.saveMenuId(menuId);
    return menuId;
  }

  Future<String> createNewMenu() async {
    final menuId = await _apiClient.fetchMenuId();
    await _storageService.saveMenuId(menuId);
    _menuIdFuture = Future.value(menuId);
    return menuId;
  }

  Future<void> joinMenu(String menuId) async {
    await _apiClient.validateMenuId(menuId);
    await _storageService.saveMenuId(menuId);
    _menuIdFuture = Future.value(menuId);
  }
}
