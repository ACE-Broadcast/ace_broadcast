import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:post_ace/utils/theme.dart';
import 'screens/selection_screen.dart';
import 'package:provider/provider.dart';
import 'utils/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final themeProvider = context.watch<ThemeProvider>();
        final useDynamicColor =
            Platform.isAndroid && themeProvider.useDynamicColor;

        // Modify dynamic light scheme if available
        ColorScheme lightScheme = useDynamicColor && lightDynamic != null
            ? lightDynamic.harmonized().copyWith(
                  // Override specific colors in dynamic scheme
                  shadow: Colors.black.withValues(alpha: 0.1),
                )
            : lightColorScheme;

        ColorScheme darkScheme = useDynamicColor && darkDynamic != null
            ? darkDynamic.harmonized()
            : darkColorScheme;

        return MaterialApp(
          title: 'College Updates',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            // Add other theme properties
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            // Add other theme properties
          ),
          home: const SelectionScreen(),
        );
      },
    );
  }
}
