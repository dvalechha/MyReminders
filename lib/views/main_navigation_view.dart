import 'package:flutter/material.dart';
import 'welcome_view.dart';
import 'settings_view.dart';

/// Global keys for nested navigators - allows external access to push routes
class MainNavigationKeys {
  static final GlobalKey<NavigatorState> homeNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> settingsNavigatorKey = GlobalKey<NavigatorState>();
}

/// Main navigation view with bottom navigation bar
/// Uses nested Navigators to keep bottom bar visible when navigating within tabs
class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _selectedIndex = 0;
  bool _showBottomBar = true;

  void _onItemTapped(int index) {
    // If tapping the same tab, pop to root
    if (index == _selectedIndex) {
      if (index == 0) {
        MainNavigationKeys.homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else {
        MainNavigationKeys.settingsNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    } else {
      // When switching tabs, ensure the target tab's navigator is at root
      // This prevents showing nested routes from the previous tab
      if (index == 0) {
        // Switching to Home tab - ensure it's at root
        MainNavigationKeys.homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else {
        // Switching to More tab - ensure it's at root
        MainNavigationKeys.settingsNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Called by nested navigators when a route is pushed/popped
  void updateBottomBarVisibility(bool show) {
    if (_showBottomBar != show) {
      setState(() {
        _showBottomBar = show;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _NestedNavigator(
            navigatorKey: MainNavigationKeys.homeNavigatorKey,
            onRouteChanged: updateBottomBarVisibility,
            child: const WelcomeView(),
          ),
          _NestedNavigator(
            navigatorKey: MainNavigationKeys.settingsNavigatorKey,
            onRouteChanged: updateBottomBarVisibility,
            child: const SettingsView(),
          ),
        ],
      ),
      bottomNavigationBar: _showBottomBar
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              iconSize: 22,
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.home),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.more_horiz),
                  ),
                  label: 'More',
                ),
              ],
            )
          : null,
    );
  }
}

/// Nested navigator widget that manages its own navigation stack
class _NestedNavigator extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  final void Function(bool show) onRouteChanged;

  const _NestedNavigator({
    required this.navigatorKey,
    required this.child,
    required this.onRouteChanged,
  });

  @override
  State<_NestedNavigator> createState() => _NestedNavigatorState();
}

class _NestedNavigatorState extends State<_NestedNavigator> {
  final _routeObserver = _BottomBarRouteObserver();

  @override
  void initState() {
    super.initState();
    _routeObserver.onRouteChanged = _handleRouteChange;
  }

  void _handleRouteChange(Route<dynamic>? route, bool isPopping) {
    if (route == null) {
      // Back to root, show bottom bar
      widget.onRouteChanged(true);
      return;
    }

    // Check if this is a form screen that should hide the bottom bar
    final routeName = route.settings.name ?? '';
    final lowerName = routeName.toLowerCase();
    
    final shouldHide = lowerName == 'subscriptionformview' ||
        lowerName == 'appointmentformview' ||
        lowerName == 'taskformview' ||
        lowerName.contains('changepassword') ||
        lowerName.contains('deleteaccount') ||
        lowerName.contains('accountprofile');
    
    debugPrint('🔍 [NestedNavigator] Route change - routeName: "$routeName", shouldHide: $shouldHide, isPopping: $isPopping');
    
    widget.onRouteChanged(!shouldHide);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      observers: [_routeObserver],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => widget.child,
        );
      },
    );
  }
}

/// Route observer for nested navigators
class _BottomBarRouteObserver extends NavigatorObserver {
  void Function(Route<dynamic>? route, bool isPopping)? onRouteChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // Notify after the push completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onRouteChanged?.call(route, false);
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Notify with the previous route (now on top)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onRouteChanged?.call(previousRoute, true);
    });
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    onRouteChanged?.call(newRoute, false);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    onRouteChanged?.call(previousRoute, true);
  }
}

