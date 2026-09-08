import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_menu/constants/consts.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/l10n/app_localizations.dart';
import 'package:shared_menu/services/meal_service.dart';
import 'package:shared_menu/services/menu_service.dart';
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

class _DailyScrollViewState extends State<DailyScrollView>
    with WidgetsBindingObserver {
  late final MealService _mealService;
  late final MenuService _menuService;
  late Future<List<Meal>> mealData;
  late List<DateTime> dates;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mealService = context.read<MealService>();
    _menuService = context.read<MenuService>();
    dates = _generateDates();
    mealData = _mealService.fetchMeals();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    final refreshedDates = _generateDates();
    if (refreshedDates.first == dates.first) {
      return;
    }
    setState(() {
      dates = refreshedDates;
      mealData = _mealService.fetchMeals();
    });
  }

  List<DateTime> _generateDates() {
    final now = DateTime.now();
    return List<DateTime>.generate(
        Consts.days, (index) => DateTime(now.year, now.month, now.day + index));
  }

  Map<(DateTime, MealType), Meal> _indexMealsByDay(List<Meal> meals) {
    final index = <(DateTime, MealType), Meal>{};
    for (final Meal meal in meals) {
      index.putIfAbsent((meal.parseDay(), meal.mealType), () => meal);
    }
    return index;
  }

  void _reloadMeals() {
    setState(() {
      mealData = _mealService.fetchMeals();
    });
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
    final l10n = AppLocalizations.of(context);
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
      await _menuService.joinMenu(scannedMenuId);
      if (!mounted) {
        return;
      }
      _reloadMeals();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorJoinMenuFailed)),
      );
    }
  }

  Future<void> _createNewMenu() async {
    final l10n = AppLocalizations.of(context);
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
      await _menuService.createNewMenu();
      if (!mounted) {
        return;
      }
      _reloadMeals();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorCreateMenuFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: FutureBuilder<List<Meal>>(
        future: mealData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.errorLoadingMeals),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reloadMeals,
                    child: Text(l10n.labelRetry),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final mealsByDay = _indexMealsByDay(snapshot.data!);
            return RefreshIndicator(
              onRefresh: () async {
                final refreshed = _mealService.fetchMeals();
                setState(() {
                  mealData = refreshed;
                });
                try {
                  await refreshed;
                } catch (_) {
                  // Surfaced by the FutureBuilder on the next build.
                }
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
                            child: Text(l10n.menuActionCreate),
                          ),
                          PopupMenuItem(
                            value: MenuAction.join,
                            child: Text(l10n.menuActionJoin),
                          ),
                          PopupMenuItem(
                            value: MenuAction.share,
                            child: Text(l10n.menuActionShare),
                          ),
                        ],
                      ),
                    ],
                    flexibleSpace: Container(
                      decoration:
                          BoxDecoration(color: theme.colorScheme.primary),
                      child: FlexibleSpaceBar(
                        titlePadding: const EdgeInsetsDirectional.only(
                            start: 16.0, bottom: 16.0),
                        title: Text(
                          l10n.appTitle,
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
                              )),
                            )),
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
                              lunchMeal:
                                  mealsByDay[(dates[index], MealType.lunch)],
                              dinnerMeal:
                                  mealsByDay[(dates[index], MealType.dinner)],
                              onMealUpdated: _reloadMeals,
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
