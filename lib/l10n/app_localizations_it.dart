// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Shared menu';

  @override
  String get labelOk => 'Ok';

  @override
  String get labelCancel => 'Annulla';

  @override
  String get labelLunch => 'Pranzo';

  @override
  String get labelDinner => 'Cena';

  @override
  String get labelRetry => 'Riprova';

  @override
  String get errorLoadingMeals => 'Impossibile caricare i menu';

  @override
  String get errorUpdateFailed => 'Impossibile salvare il pasto';

  @override
  String get menuActionCreate => 'Crea nuovo menu';

  @override
  String get menuActionJoin => 'Unisciti a un menu';

  @override
  String get menuActionShare => 'Condividi il mio menu';

  @override
  String get createMenuConfirmMessage =>
      'Tutti i dati attuali andranno persi. Vuoi continuare?';

  @override
  String get errorCreateMenuFailed => 'Impossibile creare il nuovo menu';

  @override
  String get shareMenuInstruction =>
      'Inquadra questo codice QR per unirti al menu';

  @override
  String get errorLoadingMenuId => 'Impossibile caricare l\'id del menu';
}
