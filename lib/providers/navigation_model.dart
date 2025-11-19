import 'package:flutter/material.dart';

class NavigationModel extends ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void popToRoot() {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  void navigateTo(Widget page) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

