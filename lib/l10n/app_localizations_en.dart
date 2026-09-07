// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shared menu';

  @override
  String get labelOk => 'Ok';

  @override
  String get labelCancel => 'Cancel';

  @override
  String get labelLunch => 'Lunch';

  @override
  String get labelDinner => 'Dinner';

  @override
  String get labelRetry => 'Retry';

  @override
  String get errorLoadingMeals => 'Failed to load meals';

  @override
  String get errorUpdateFailed => 'Failed to save meal';

  @override
  String get menuActionCreate => 'Create new menu';

  @override
  String get menuActionJoin => 'Join a menu';

  @override
  String get menuActionShare => 'Share my menu';

  @override
  String get createMenuConfirmMessage =>
      'All current data will be lost. Do you want to continue?';

  @override
  String get errorCreateMenuFailed => 'Failed to create new menu';

  @override
  String get shareMenuInstruction => 'Scan this QR code to join the menu';

  @override
  String get errorLoadingMenuId => 'Failed to load menu id';

  @override
  String get joinMenuConfirmMessage =>
      'If you join another menu, all the current data will be lost. Do you want to continue?';

  @override
  String get scanMenuInstruction =>
      'Scan the QR code of the menu you want to join';

  @override
  String get errorJoinMenuFailed => 'Failed to join the menu';
}
