import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void logIn() => state = true;
  void logOut() => state = false;
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

