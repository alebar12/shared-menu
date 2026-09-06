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
    final mealType = (json['mealType'] as String?)?.toLowerCase();
    return Meal(
      day: json['day'] as String? ?? '',
      mealType: MealType.values.firstWhere((meal) => mealType == meal.name.toLowerCase(),
          orElse: () => MealType.lunch),
      meal: json['meal'] as String? ?? '',
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