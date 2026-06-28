import 'dart:ui';
import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'pages/entry_page.dart';
import 'pages/movie_billboard_page.dart';

void main() {
  runApp(const AntigravityAuthApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class AntigravityAuthApp extends StatelessWidget {
  const AntigravityAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antigravity Portal',
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(

        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.fondoBase,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.acentoVioleta,
          secondary: AppColors.acentoMagenta,
          error: AppColors.errorNeon,
        ),
        fontFamily: 'Roboto', // Native clean font fallback
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textoPrincipal),
          bodyMedium: TextStyle(color: AppColors.textoSecundario),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const EntryPage(),
        '/billboard': (context) => const MovieBillboardPage(),
      },
    );
  }
}
