import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class CryptoService {
  CryptoService({Random? random}) : _random = random ?? Random.secure();

  static const String _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static const int _secretLength = 32;

  final Random _random;
  final AesGcm _algorithm = AesGcm.with256bits();

  String generateSecret() {
    return String.fromCharCodes(
      List<int>.generate(_secretLength,
          (_) => _alphabet.codeUnitAt(_random.nextInt(_alphabet.length))),
    );
  }

  Future<String> encrypt(String plainText, String secret) async {
    final secretBox = await _algorithm.encryptString(
      plainText,
      secretKey: await _secretKey(secret),
    );
    return base64Encode(secretBox.concatenation());
  }

  Future<String> decrypt(String cipherText, String secret) async {
    final secretBox = SecretBox.fromConcatenation(
      base64Decode(cipherText),
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    return _algorithm.decryptString(
      secretBox,
      secretKey: await _secretKey(secret),
    );
  }

  Future<SecretKey> _secretKey(String secret) async {
    final hash = await Sha256().hash(utf8.encode(secret));
    return SecretKey(hash.bytes);
  }
}
