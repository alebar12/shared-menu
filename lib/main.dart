import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_menu/constants/consts.dart';
import 'package:shared_menu/widgets/daily_scroll_view.dart';
import 'package:intl/date_symbol_data_local.dart';



void main() {
  //debugPaintSizeEnabled = true;
  initializeDateFormatting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: Consts.title,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        ),
        home: const DailyScrollView(),
      ),
    );
  }
}



class MyAppState extends ChangeNotifier {

}




