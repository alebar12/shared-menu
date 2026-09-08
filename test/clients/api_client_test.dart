import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/constants/consts.dart';
import 'package:shared_menu/dto/meal.dart';

void main() {
  group('fetchMenuId', () {
    test('returns the menu id from the response body', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url, Uri.parse('${Consts.apiBaseUrl}/menuId'));
          return http.Response('{"menuId":"menu-1"}', 200);
        }),
      );

      expect(await client.fetchMenuId(), 'menu-1');
    });

    test('throws ApiException on a non 200 response', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async => http.Response('', 500)),
      );

      await expectLater(
        client.fetchMenuId(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', 'Failed to fetch menu id')),
      );
    });
  });

  group('validateMenuId', () {
    test('posts the menu id', () async {
      late http.Request captured;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('', 204);
        }),
      );

      await client.validateMenuId('menu-1');

      expect(captured.method, 'POST');
      expect(captured.url, Uri.parse('${Consts.apiBaseUrl}/menuId'));
      expect(
          captured.headers['Content-Type'], 'application/json; charset=UTF-8');
      expect(jsonDecode(captured.body), <String, String>{'menuId': 'menu-1'});
    });

    test('throws ApiException outside the 2xx range', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async => http.Response('', 404)),
      );

      await expectLater(
        client.validateMenuId('menu-1'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Failed to validate menu id')),
      );
    });
  });

  group('fetchMeals', () {
    test('sends the menu id header and parses the meals', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url, Uri.parse('${Consts.apiBaseUrl}/meals'));
          expect(request.headers['x-menu-id'], 'menu-1');
          return http.Response(
            '[{"day":"2024-01-15","mealType":"LUNCH","meal":"Pasta"}]',
            200,
          );
        }),
      );

      final meals = await client.fetchMeals('menu-1');

      expect(meals, hasLength(1));
      expect(meals.single.meal, 'Pasta');
      expect(meals.single.mealType, MealType.lunch);
    });

    test('throws ApiException on a non 200 response', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async => http.Response('', 503)),
      );

      await expectLater(
        client.fetchMeals('menu-1'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Failed to fetch meals')),
      );
    });
  });

  group('postMeal', () {
    test('sends the menu id header and the formatted payload', () async {
      late http.Request captured;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('', 200);
        }),
      );

      await client.postMeal(
          'menu-1', 'Pizza', DateTime(2024, 1, 5), MealType.dinner);

      expect(captured.method, 'POST');
      expect(captured.url, Uri.parse('${Consts.apiBaseUrl}/meals'));
      expect(captured.headers['x-menu-id'], 'menu-1');
      expect(jsonDecode(captured.body), <String, String>{
        'meal': 'Pizza',
        'mealType': 'DINNER',
        'day': '2024-01-05',
      });
    });

    test('throws ApiException outside the 2xx range', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async => http.Response('', 400)),
      );

      await expectLater(
        client.postMeal(
            'menu-1', 'Pizza', DateTime(2024, 1, 5), MealType.lunch),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Failed to update meal')),
      );
    });
  });

  group('close', () {
    test('closes the underlying http client', () {
      final httpClient = _RecordingClient();
      ApiClient(httpClient: httpClient).close();

      expect(httpClient.closed, isTrue);
    });
  });
}

class _RecordingClient extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(const Stream<List<int>>.empty(), 200);

  @override
  void close() {
    closed = true;
    super.close();
  }
}
