import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/services/storage_service.dart';

class ApiClient { 

  Future<String> fetchMenuId() async {
    final response = await http
        .get(Uri.parse('https://shared-menu.alebar12.workers.dev/menuId'));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to fetch menu id');
    }
    return jsonDecode(response.body)['menuId'];
  }

  Future<List<Meal>> fetchMeals() async {
    String menuId = await StorageService().getMenuId();
    final response = await http
        .get(Uri.parse('https://shared-menu.alebar12.workers.dev/meals'),
        headers: <String, String>{
          'x-menu-id': menuId,
        },
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to fetch meals');
    }
    return compute(parseMeals, response.body);
  }

  Future<http.Response> updateMeal(String meal, DateTime day, MealType mealType, String menuId) async {
    final response = await http.post(
      Uri.parse('https://shared-menu.alebar12.workers.dev/meals'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'x-menu-id': menuId,
      },
      body: jsonEncode(<String, String>{
        'meal': meal,
        'mealType': mealType.name.toUpperCase(),
        'day': DateFormat("yyyy-MM-dd").format(day)
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, 'Failed to update meal');
    }
    return response;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

List<Meal> parseMeals(String responseBody) {
  var jsonArray = jsonDecode(responseBody) as List;
  return jsonArray.map((jsonObject) => Meal.fromJson(jsonObject)).toList();
}