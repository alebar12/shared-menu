import 'dart:async';

import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/services/storage_service.dart';

class PostedMeal {
  PostedMeal(this.menuId, this.meal, this.day, this.mealType);

  final String menuId;
  final String meal;
  final DateTime day;
  final MealType mealType;
}

class FakeApiClient extends ApiClient {
  FakeApiClient({
    this.menuIdToReturn = 'menu-1',
    this.mealsToReturn = const <Meal>[],
  });

  String menuIdToReturn;
  List<Meal> mealsToReturn;
  Object? fetchMenuIdError;
  Object? validateMenuIdError;
  Object? fetchMealsError;
  Object? postMealError;

  /// When set, [fetchMeals] only completes once this completer does.
  Completer<void>? fetchMealsGate;

  int fetchMenuIdCalls = 0;
  final List<String> validatedMenuIds = <String>[];
  final List<String> fetchMealsMenuIds = <String>[];
  final List<PostedMeal> postedMeals = <PostedMeal>[];

  @override
  Future<String> fetchMenuId() async {
    fetchMenuIdCalls++;
    if (fetchMenuIdError != null) {
      throw fetchMenuIdError!;
    }
    return menuIdToReturn;
  }

  @override
  Future<void> validateMenuId(String menuId) async {
    validatedMenuIds.add(menuId);
    if (validateMenuIdError != null) {
      throw validateMenuIdError!;
    }
  }

  @override
  Future<List<Meal>> fetchMeals(String menuId) async {
    fetchMealsMenuIds.add(menuId);
    final gate = fetchMealsGate;
    if (gate != null) {
      await gate.future;
    }
    if (fetchMealsError != null) {
      throw fetchMealsError!;
    }
    return mealsToReturn;
  }

  @override
  Future<void> postMeal(
      String menuId, String meal, DateTime day, MealType mealType) async {
    postedMeals.add(PostedMeal(menuId, meal, day, mealType));
    if (postMealError != null) {
      throw postMealError!;
    }
  }
}

class FakeStorageService extends StorageService {
  FakeStorageService({this.storedMenuId});

  String? storedMenuId;
  final List<String> savedMenuIds = <String>[];

  @override
  Future<String?> getMenuId() async => storedMenuId;

  @override
  Future<void> saveMenuId(String menuId) async {
    savedMenuIds.add(menuId);
    storedMenuId = menuId;
  }
}
