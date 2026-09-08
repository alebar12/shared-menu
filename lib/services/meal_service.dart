import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/services/menu_service.dart';

class MealService {
  MealService({
    required ApiClient apiClient,
    required MenuService menuService,
  })  : _apiClient = apiClient,
        _menuService = menuService;

  final ApiClient _apiClient;
  final MenuService _menuService;

  Future<List<Meal>> fetchMeals() async {
    final menuId = await _menuService.currentMenuId();
    return _apiClient.fetchMeals(menuId);
  }

  Future<void> updateMeal(String meal, DateTime day, MealType mealType) async {
    final menuId = await _menuService.currentMenuId();
    await _apiClient.postMeal(menuId, meal, day, mealType);
  }
}
