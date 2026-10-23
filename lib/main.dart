import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const IotApp());
}

class IotApp extends StatelessWidget {
  const IotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Monitor',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: HomeScreen(),
      ),
    );
  }
}
