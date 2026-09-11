import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/menu_credentials.dart';
import 'package:shared_menu/services/crypto_service.dart';
import 'package:shared_menu/services/storage_service.dart';

class MenuService {
  MenuService({
    required ApiClient apiClient,
    required StorageService storageService,
    required CryptoService cryptoService,
  })  : _apiClient = apiClient,
        _storageService = storageService,
        _cryptoService = cryptoService;

  final ApiClient _apiClient;
  final StorageService _storageService;
  final CryptoService _cryptoService;

  Future<MenuCredentials>? _credentialsFuture;

  Future<MenuCredentials> currentCredentials() async {
    _credentialsFuture ??= _readOrCreateCredentials();
    try {
      return await _credentialsFuture!;
    } catch (_) {
      _credentialsFuture = null;
      rethrow;
    }
  }

  Future<String> currentMenuId() async {
    return (await currentCredentials()).menuId;
  }

  Future<MenuCredentials> _readOrCreateCredentials() async {
    final menuId = await _storageService.getMenuId();
    final secret = await _storageService.getMenuSecret();
    if (menuId != null && secret != null) {
      return MenuCredentials(menuId: menuId, secret: secret);
    }
    return _createCredentials();
  }

  Future<MenuCredentials> createNewMenu() async {
    final credentials = await _createCredentials();
    _credentialsFuture = Future.value(credentials);
    return credentials;
  }

  Future<void> joinMenu(String qrPayload) async {
    final credentials = MenuCredentials.fromQrPayload(qrPayload);
    await _apiClient.validateMenuId(credentials.menuId);
    await _storageService.saveMenuId(credentials.menuId);
    await _storageService.saveMenuSecret(credentials.secret);
    _credentialsFuture = Future.value(credentials);
  }

  Future<MenuCredentials> _createCredentials() async {
    final menuId = await _apiClient.fetchMenuId();
    final secret = _cryptoService.generateSecret();
    await _storageService.saveMenuId(menuId);
    await _storageService.saveMenuSecret(secret);
    return MenuCredentials(menuId: menuId, secret: secret);
  }
}
