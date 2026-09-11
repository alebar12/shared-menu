import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/services/crypto_service.dart';
import 'package:shared_menu/services/menu_service.dart';

class MealService {
  MealService({
    required ApiClient apiClient,
    required MenuService menuService,
    required CryptoService cryptoService,
  })  : _apiClient = apiClient,
        _menuService = menuService,
        _cryptoService = cryptoService;

  final ApiClient _apiClient;
  final MenuService _menuService;
  final CryptoService _cryptoService;

  Future<List<Meal>> fetchMeals() async {
    final credentials = await _menuService.currentCredentials();
    final meals = await _apiClient.fetchMeals(credentials.menuId);
    final decrypted = <Meal>[];
    for (final Meal meal in meals) {
      try {
        decrypted.add(Meal(
          day: meal.day,
          mealType: meal.mealType,
          meal: await _cryptoService.decrypt(meal.meal, credentials.secret),
        ));
      } catch (_) {}
    }
    if (meals.isNotEmpty && decrypted.isEmpty) {
      throw CorruptedMenuException();
    }
    return decrypted;
  }

  Future<void> updateMeal(String meal, DateTime day, MealType mealType) async {
    final credentials = await _menuService.currentCredentials();
    final encrypted = await _cryptoService.encrypt(meal, credentials.secret);
    await _apiClient.postMeal(credentials.menuId, encrypted, day, mealType);
  }
}

class CorruptedMenuException implements Exception {
  @override
  String toString() => 'CorruptedMenuException';
}
