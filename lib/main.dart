import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/l10n/app_localizations.dart';
import 'package:shared_menu/services/crypto_service.dart';
import 'package:shared_menu/services/meal_service.dart';
import 'package:shared_menu/services/menu_service.dart';
import 'package:shared_menu/services/storage_service.dart';
import 'package:shared_menu/widgets/daily_scroll_view.dart';

void main() {
  initializeDateFormatting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (context) => ApiClient(),
          dispose: (context, apiClient) => apiClient.close(),
        ),
        Provider(create: (context) => StorageService()),
        Provider(create: (context) => CryptoService()),
        Provider(
          create: (context) => MenuService(
            apiClient: context.read<ApiClient>(),
            storageService: context.read<StorageService>(),
            cryptoService: context.read<CryptoService>(),
          ),
        ),
        Provider(
          create: (context) => MealService(
            apiClient: context.read<ApiClient>(),
            menuService: context.read<MenuService>(),
            cryptoService: context.read<CryptoService>(),
          ),
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        ),
        home: const DailyScrollView(),
      ),
    );
  }
}
