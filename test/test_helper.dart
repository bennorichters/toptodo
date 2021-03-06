import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TestableWidgetWithMediaQuery extends StatelessWidget {
  const TestableWidgetWithMediaQuery({
    this.child,
    this.width = 600,
    this.height = 800,
    this.routes,
    this.navigatorObservers,
  });

  final Widget child;
  final double width;
  final double height;
  final Map<String, WidgetBuilder> routes;
  final List<NavigatorObserver> navigatorObservers;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: routes ?? const <String, WidgetBuilder>{},
      navigatorObservers: navigatorObservers ?? const <NavigatorObserver>[],
      home: Material(
        child: MediaQuery(
          data: MediaQueryData.fromWindow(ui.window).copyWith(
            size: Size(width, height),
          ),
          child: child,
        ),
      ),
    );
  }
}

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}
