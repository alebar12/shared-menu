import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/services/storage_service.dart';

class ApiClient {

  Future<List<Meal>> fetchMeals() async {
    String menuId = await StorageService().getMenuId();
    final response = await http
        .get(Uri.parse(''));

    return compute(parseMeals, response.body);
  }

  List<Meal> parseMeals(String responseBody) {
    var jsonArray = jsonDecode(responseBody) as List;
    return jsonArray.map((jsonObject) => Meal.fromJson(jsonObject)).toList();
  }

  Future<http.Response> updateMeal(String meal, DateTime day, MealType mealType, String menuId) async {
    return await http.post(
      Uri.parse(''),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'meal': meal,
        'mealType': mealType.name,
        'menuId': menuId,
        'day': DateFormat("y-M-d").format(day)
      }),
    );
  }
}