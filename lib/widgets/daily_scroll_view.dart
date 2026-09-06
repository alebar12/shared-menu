
import 'package:flutter/material.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/constants/consts.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/widgets/day_card.dart';

class DailyScrollView extends StatefulWidget {
  const DailyScrollView({
    super.key,
  });

  @override
  State<DailyScrollView> createState() => _DailyScrollViewState();
}

class _DailyScrollViewState extends State<DailyScrollView> {
  Future<List<Meal>> mealData = ApiClient().fetchMeals();
  List<DateTime> dates = List.generate(Consts.days, (index) =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + index));

  Meal? extractMealForDay (List<Meal>? meals,  DateTime day, MealType mealType) {
    for (Meal meal in meals!) {
      if (meal.mealType == mealType && meal.parseDay() == day) {
        return meal;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<List<Meal>>(
        future: mealData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  mealData = ApiClient().fetchMeals();
                });
              },
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    pinned: true,
                    snap: false,
                    floating: false,
                    expandedHeight: 300.0,
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                      ),
                      child: FlexibleSpaceBar(
                        title: const Text(Consts.title),
                        background: Stack(
                          children: [
                            const Positioned.fill(
                              child: Image(
                                image: AssetImage('images/header.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                                child: Container(
                                  decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black,
                                          Colors.transparent,
                                        ],
                                      )
                                  ),
                                )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            widthFactor: 1,
                            child: DayCard(
                              date: dates[index],
                              lunchMeal: extractMealForDay(snapshot.data, dates[index], MealType.lunch),
                              dinnerMeal: extractMealForDay(snapshot.data, dates[index], MealType.dinner),
                              onMealUpdated: () {
                                setState(() {
                                  mealData = ApiClient().fetchMeals();
                                });
                              },
                            ),
                          ),
                        );
                      },
                      childCount: Consts.days,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}