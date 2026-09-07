
import 'package:flutter/material.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/constants/consts.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/l10n/app_localizations.dart';
import 'package:shared_menu/widgets/day_card.dart';
import 'package:shared_menu/widgets/scan_menu_view.dart';
import 'package:shared_menu/widgets/share_menu_view.dart';

enum MenuAction { create, join, share }

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

  void _onMenuAction(MenuAction action) {
    switch (action) {
      case MenuAction.create:
        _createNewMenu();
        break;
      case MenuAction.join:
        _joinMenu();
        break;
      case MenuAction.share:
        _shareMenu();
        break;
    }
  }

  void _shareMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShareMenuView()),
    );
  }

  Future<void> _joinMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.menuActionJoin),
          content: Text(l10n.joinMenuConfirmMessage),
          actions: <Widget>[
            MaterialButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.labelCancel),
            ),
            MaterialButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.labelOk),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final scannedMenuId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScanMenuView()),
    );
    if (scannedMenuId == null || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient().joinMenu(scannedMenuId);
      if (!mounted) {
        return;
      }
      setState(() {
        mealData = ApiClient().fetchMeals();
      });
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorJoinMenuFailed)),
      );
    }
  }

  Future<void> _createNewMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.menuActionCreate),
          content: Text(l10n.createMenuConfirmMessage),
          actions: <Widget>[
            MaterialButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.labelCancel),
            ),
            MaterialButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.labelOk),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient().createNewMenu();
      if (!mounted) {
        return;
      }
      setState(() {
        mealData = ApiClient().fetchMeals();
      });
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorCreateMenuFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<List<Meal>>(
        future: mealData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.errorLoadingMeals),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        mealData = ApiClient().fetchMeals();
                      });
                    },
                    child: Text(AppLocalizations.of(context)!.labelRetry),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
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
                    actions: [
                      PopupMenuButton<MenuAction>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: _onMenuAction,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: MenuAction.create,
                            child: Text(
                                AppLocalizations.of(context)!.menuActionCreate),
                          ),
                          PopupMenuItem(
                            value: MenuAction.join,
                            child: Text(
                                AppLocalizations.of(context)!.menuActionJoin),
                          ),
                          PopupMenuItem(
                            value: MenuAction.share,
                            child: Text(
                                AppLocalizations.of(context)!.menuActionShare),
                          ),
                        ],
                      ),
                    ],
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                      ),
                      child: FlexibleSpaceBar(
                        title: Text(
                          AppLocalizations.of(context)!.appTitle,
                          style: const TextStyle(color: Colors.white),
                        ),
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