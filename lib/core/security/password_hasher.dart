import 'dart:convert';

import 'package:crypto/crypto.dart';

String hashPassword(String username, String password) {
  final bytes = utf8.encode('${username.trim()}::$password');
  return sha256.convert(bytes).toString();
}
