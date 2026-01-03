// app.dart
// Main application setup and configuration

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes.dart';
import 'theme.dart';
import 'bindings/initial_binding.dart';

class HomeServicesApp extends StatelessWidget {
  const HomeServicesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Fix It Now',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: AppRoutes.welcome,
      getPages: AppRoutes.getPages,
      defaultTransition: Transition.fadeIn,
      initialBinding: InitialBinding(),
      enableLog: true,
      logWriterCallback: (String text, {bool isError = false}) {
        if (isError) {
          print('Error: $text');
        } else {
          print('Log: $text');
        }
      },
    );
  }
}