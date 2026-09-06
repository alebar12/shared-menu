import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<String> getMenuId() async {
    final prefs = await SharedPreferences.getInstance();
    String menuId = prefs.getString("menuID") ?? await _generateAndSaveMenuId(prefs);
    return menuId;
  }

  Future<String> _generateAndSaveMenuId(SharedPreferences prefs) async {
    // const Uuid().v4()
    String menuid = "qweioqniweqowe";
    await prefs.setString('menuID', menuid);
    return menuid;
  }
}