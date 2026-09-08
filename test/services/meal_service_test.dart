import 'package:flutter_test/flutter_test.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/services/meal_service.dart';
import 'package:shared_menu/services/menu_service.dart';

import '../fakes.dart';

void main() {
  late FakeApiClient apiClient;
  late FakeStorageService storageService;
  late MealService mealService;

  setUp(() {
    apiClient = FakeApiClient();
    storageService = FakeStorageService(storedMenuId: 'menu-1');
    mealService = MealService(
      apiClient: apiClient,
      menuService: MenuService(
        apiClient: apiClient,
        storageService: storageService,
      ),
    );
  });

  group('fetchMeals', () {
    test('fetches the meals of the current menu', () async {
      apiClient.mealsToReturn = <Meal>[
        Meal(day: '2024-01-15', mealType: MealType.lunch, meal: 'Pasta'),
      ];

      final meals = await mealService.fetchMeals();

      expect(meals.single.meal, 'Pasta');
      expect(apiClient.fetchMealsMenuIds, <String>['menu-1']);
    });

    test('propagates the api failure', () async {
      apiClient.fetchMealsError = ApiException(500, 'boom');

      await expectLater(mealService.fetchMeals(), throwsA(isA<ApiException>()));
    });

    test('fails without calling the api when the menu id cannot be resolved',
        () async {
      storageService.storedMenuId = null;
      apiClient.fetchMenuIdError = ApiException(500, 'boom');

      await expectLater(mealService.fetchMeals(), throwsA(isA<ApiException>()));
      expect(apiClient.fetchMealsMenuIds, isEmpty);
    });
  });

  group('updateMeal', () {
    test('posts the meal for the current menu', () async {
      await mealService.updateMeal(
          'Pizza', DateTime(2024, 1, 5), MealType.dinner);

      final posted = apiClient.postedMeals.single;
      expect(posted.menuId, 'menu-1');
      expect(posted.meal, 'Pizza');
      expect(posted.day, DateTime(2024, 1, 5));
      expect(posted.mealType, MealType.dinner);
    });

    test('propagates the api failure', () async {
      apiClient.postMealError = ApiException(400, 'boom');

      await expectLater(
        mealService.updateMeal('Pizza', DateTime(2024, 1, 5), MealType.lunch),
        throwsA(isA<ApiException>()),
      );
    });

    test('fails without posting when the menu id cannot be resolved', () async {
      storageService.storedMenuId = null;
      apiClient.fetchMenuIdError = ApiException(500, 'boom');

      await expectLater(
        mealService.updateMeal('Pizza', DateTime(2024, 1, 5), MealType.lunch),
        throwsA(isA<ApiException>()),
      );
      expect(apiClient.postedMeals, isEmpty);
    });
  });
}
