import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/l10n/app_localizations.dart';
import 'package:shared_menu/services/storage_service.dart';

class DayCard extends StatelessWidget {
  const DayCard({
    super.key,
    required this.date,
    required this.lunchMeal,
    required this.dinnerMeal,
    required this.onMealUpdated,
  });

  final DateTime date;
  final Meal? lunchMeal;
  final Meal? dinnerMeal;
  final VoidCallback onMealUpdated;

  String getFormattedDate(String languageTag) {
    return DateFormat("EEEE dd MMMM", languageTag).format(date);
  }

  Future<void> _displayTextInputDialog(BuildContext context, String defaultValue, DateTime refDate,
      MealType mealType, VoidCallback onMealUpdated) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
        context: context,
        builder: (context) {
          var controller = TextEditingController(
              text: defaultValue
          );

          return AlertDialog(
            content: SizedBox(
              width: 300,
              child: TextField(
                onChanged: (value) {

                },
                controller: controller,
                autofocus: true,
                minLines: 1,
                maxLines: 5,
              ),
            ),
            actions: <Widget>[
              MaterialButton(
                child: Text(l10n.labelCancel),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              MaterialButton(
                child: Text(l10n.labelOk),
                onPressed: () {
                  final navigator = Navigator.of(context);
                  StorageService().getMenuId().then((value) => {
                    ApiClient().updateMeal(controller.text, refDate, mealType, value).whenComplete(() {
                      navigator.pop();
                      onMealUpdated();
                    })
                  });

                },
              ),
            ],
          );
        });
  }

  Color? _getCartColor(ThemeData theme) {
    if (date.weekday == 7) {
      return theme.colorScheme.inversePrimary;
    } else {
      return theme.colorScheme.primaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    Color? iconAndTextColor = theme.colorScheme.onPrimaryContainer;
    final textStyle = theme.textTheme.bodySmall!.copyWith(
      color: iconAndTextColor,
    );

    var languageTag = Localizations.localeOf(context).toString();

    final titleTextStyle = theme.textTheme.titleSmall!.copyWith(
      color: iconAndTextColor,
    );


    return Card(
      color: _getCartColor(theme),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(getFormattedDate(languageTag), style: titleTextStyle),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 6,
                  child: Text("${l10n.labelLunch}: ${(lunchMeal?.meal ?? '')}" , style: textStyle),
                ),
                Expanded(
                  flex: 1,
                  child: IconButton(
                    onPressed: () {
                      _displayTextInputDialog(context, (lunchMeal?.meal ?? ''), date, MealType.lunch, onMealUpdated);
                    },
                    color: iconAndTextColor,
                    icon: const Icon(Icons.edit)
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    flex: 6,
                    child: Text("${l10n.labelDinner}: ${(dinnerMeal?.meal ?? '')}" , style: textStyle)
                ),
                Expanded(
                  flex: 1,
                  child: IconButton(
                      onPressed: () {
                        _displayTextInputDialog(context, (dinnerMeal?.meal ?? ''), date, MealType.dinner, onMealUpdated);
                      },
                      color: iconAndTextColor,
                      icon: const Icon(Icons.edit)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}