import 'dart:convert';

class MenuCredentials {
  final String menuId;
  final String secret;

  const MenuCredentials({
    required this.menuId,
    required this.secret,
  });

  factory MenuCredentials.fromQrPayload(String payload) {
    Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      throw FormatException('Not a menu payload', payload);
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Not a menu payload', payload);
    }
    final menuId = decoded['menuId'];
    final secret = decoded['secret'];
    if (menuId is! String ||
        menuId.isEmpty ||
        secret is! String ||
        secret.isEmpty) {
      throw FormatException('Incomplete menu payload', payload);
    }
    return MenuCredentials(menuId: menuId, secret: secret);
  }

  String toQrPayload() {
    return jsonEncode(<String, String>{
      'menuId': menuId,
      'secret': secret,
    });
  }
}
