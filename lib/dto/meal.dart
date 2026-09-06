import 'package:intl/intl.dart';

class Meal {
  final String day;
  final MealType mealType;
  final String meal;

  const Meal({
    required this.day,
    required this.mealType,
    required this.meal,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      day: json['day'],
      mealType: MealType.values.firstWhere((meal) => json['mealType'].toLowerCase() == meal.name.toLowerCase(),
          orElse: () => MealType.lunch),
      meal: json['meal'],
    );
  }

  DateTime parseDay(){
    return DateFormat("y-M-d").parse(day);
  }
}

enum MealType {
  lunch,
  dinner
}