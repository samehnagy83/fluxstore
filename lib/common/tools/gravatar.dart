import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

String getGravatarHash(String? email) {
  final emailSanitized = '$email'.trim().toLowerCase();
  final md5 = crypto.md5.convert(utf8.encode(emailSanitized)).toString();
  return md5;
}

String getGravatarUrlFromHash(
  String hash, {
  int size = 30,
}) {
  return 'https://www.gravatar.com/avatar/$hash?s=$size&d=retro';
}

String getGravatarUrl(
  String? email, {
  int size = 30,
}) {
  // Allow null email as string
  final hash = getGravatarHash('$email');
  return getGravatarUrlFromHash(hash, size: size);
}
