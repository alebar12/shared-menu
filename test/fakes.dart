import 'dart:async';

import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/dto/menu_credentials.dart';
import 'package:shared_menu/services/crypto_service.dart';
import 'package:shared_menu/services/storage_service.dart';

/// The secret the fakes store next to the menu id.
const String fakeMenuSecret = 'fake-menu-secret';

String fakeQrPayload({
  String menuId = 'menu-1',
  String secret = fakeMenuSecret,
}) {
  return MenuCredentials(menuId: menuId, secret: secret).toQrPayload();
}

/// Encrypts [name] the way the server stores it.
Future<String> encryptMealName(String name,
    {String secret = fakeMenuSecret}) async {
  return CryptoService().encrypt(name, secret);
}

Future<String> decryptMealName(String cipherText,
    {String secret = fakeMenuSecret}) async {
  return CryptoService().decrypt(cipherText, secret);
}

Future<Meal> encryptedMeal({
  required String day,
  required MealType mealType,
  required String meal,
  String secret = fakeMenuSecret,
}) async {
  return Meal(
    day: day,
    mealType: mealType,
    meal: await encryptMealName(meal, secret: secret),
  );
}

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

  /// Overrides [mealsToReturn] for the listed menu ids.
  final Map<String, List<Meal>> mealsByMenuId = <String, List<Meal>>{};

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
    return mealsByMenuId[menuId] ?? mealsToReturn;
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
  FakeStorageService({this.storedMenuId, String? storedMenuSecret})
      : storedMenuSecret =
            storedMenuSecret ?? (storedMenuId == null ? null : fakeMenuSecret);

  String? storedMenuId;
  String? storedMenuSecret;
  final List<String> savedMenuIds = <String>[];
  final List<String> savedMenuSecrets = <String>[];

  @override
  Future<String?> getMenuId() async => storedMenuId;

  @override
  Future<void> saveMenuId(String menuId) async {
    savedMenuIds.add(menuId);
    storedMenuId = menuId;
  }

  @override
  Future<String?> getMenuSecret() async => storedMenuSecret;

  @override
  Future<void> saveMenuSecret(String secret) async {
    savedMenuSecrets.add(secret);
    storedMenuSecret = secret;
  }
}
