import 'package:flutter_test/flutter_test.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/services/crypto_service.dart';
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
    final cryptoService = CryptoService();
    mealService = MealService(
      apiClient: apiClient,
      menuService: MenuService(
        apiClient: apiClient,
        storageService: storageService,
        cryptoService: cryptoService,
      ),
      cryptoService: cryptoService,
    );
  });

  group('fetchMeals', () {
    test('decrypts the meals of the current menu', () async {
      apiClient.mealsToReturn = <Meal>[
        await encryptedMeal(
            day: '2024-01-15', mealType: MealType.lunch, meal: 'Pasta'),
      ];

      final meals = await mealService.fetchMeals();

      expect(meals.single.meal, 'Pasta');
      expect(meals.single.day, '2024-01-15');
      expect(meals.single.mealType, MealType.lunch);
      expect(apiClient.fetchMealsMenuIds, <String>['menu-1']);
    });

    test('returns an empty list when the menu holds no meals', () async {
      expect(await mealService.fetchMeals(), isEmpty);
    });

    test('drops the meals encrypted with another secret', () async {
      apiClient.mealsToReturn = <Meal>[
        await encryptedMeal(
            day: '2024-01-15', mealType: MealType.lunch, meal: 'Pasta'),
        await encryptedMeal(
            day: '2024-01-15',
            mealType: MealType.dinner,
            meal: 'Pizza',
            secret: 'another-secret'),
      ];

      final meals = await mealService.fetchMeals();

      expect(meals.single.meal, 'Pasta');
    });

    test('throws when none of the meals can be decrypted', () async {
      apiClient.mealsToReturn = <Meal>[
        await encryptedMeal(
            day: '2024-01-15',
            mealType: MealType.lunch,
            meal: 'Pasta',
            secret: 'another-secret'),
      ];

      await expectLater(
        mealService.fetchMeals(),
        throwsA(isA<CorruptedMenuException>()),
      );
    });

    test('throws when the meal names are not encrypted at all', () async {
      apiClient.mealsToReturn = <Meal>[
        Meal(day: '2024-01-15', mealType: MealType.lunch, meal: 'Pasta'),
      ];

      await expectLater(
        mealService.fetchMeals(),
        throwsA(isA<CorruptedMenuException>()),
      );
    });

    test('propagates the api failure', () async {
      apiClient.fetchMealsError = ApiException(500, 'boom');

      await expectLater(mealService.fetchMeals(), throwsA(isA<ApiException>()));
    });

    test('fails without calling the api when the menu id cannot be resolved',
        () async {
      storageService.storedMenuId = null;
      storageService.storedMenuSecret = null;
      apiClient.fetchMenuIdError = ApiException(500, 'boom');

      await expectLater(mealService.fetchMeals(), throwsA(isA<ApiException>()));
      expect(apiClient.fetchMealsMenuIds, isEmpty);
    });
  });

  group('updateMeal', () {
    test('posts the encrypted meal for the current menu', () async {
      await mealService.updateMeal(
          'Pizza', DateTime(2024, 1, 5), MealType.dinner);

      final posted = apiClient.postedMeals.single;
      expect(posted.menuId, 'menu-1');
      expect(posted.meal, isNot('Pizza'));
      expect(await decryptMealName(posted.meal), 'Pizza');
      expect(posted.day, DateTime(2024, 1, 5));
      expect(posted.mealType, MealType.dinner);
    });

    test('uses a different cipher text for the same meal name', () async {
      await mealService.updateMeal(
          'Pizza', DateTime(2024, 1, 5), MealType.dinner);
      await mealService.updateMeal(
          'Pizza', DateTime(2024, 1, 6), MealType.dinner);

      expect(apiClient.postedMeals.first.meal,
          isNot(apiClient.postedMeals.last.meal));
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
      storageService.storedMenuSecret = null;
      apiClient.fetchMenuIdError = ApiException(500, 'boom');

      await expectLater(
        mealService.updateMeal('Pizza', DateTime(2024, 1, 5), MealType.lunch),
        throwsA(isA<ApiException>()),
      );
      expect(apiClient.postedMeals, isEmpty);
    });
  });
}
