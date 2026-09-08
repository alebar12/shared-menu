import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_menu/constants/consts.dart';
import 'package:shared_menu/dto/meal.dart';

class ApiClient {
  Future<String> fetchMenuId() async {
    final response = await http
        .get(Uri.parse('${Consts.apiBaseUrl}/menuId'));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to fetch menu id');
    }
    return jsonDecode(response.body)['menuId'];
  }

  Future<void> validateMenuId(String menuId) async {
    final response = await http.post(
      Uri.parse('${Consts.apiBaseUrl}/menuId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'menuId': menuId,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, 'Failed to validate menu id');
    }
  }

  Future<List<Meal>> fetchMeals(String menuId) async {
    final response = await http
        .get(Uri.parse('${Consts.apiBaseUrl}/meals'),
        headers: <String, String>{
          'x-menu-id': menuId,
        },
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to fetch meals');
    }
    return compute(parseMeals, response.body);
  }

  Future<void> postMeal(String menuId, String meal, DateTime day, MealType mealType) async {
    final response = await http.post(
      Uri.parse('${Consts.apiBaseUrl}/meals'),
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