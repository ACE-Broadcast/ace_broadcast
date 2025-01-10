import 'package:device_info_plus/device_info_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:post_ace/utils/theme.dart';
import 'package:post_ace/widgets/connectivity_wrapper.dart';
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

  static late int sdkInt;
  static late String manufacturer;

  static Future<bool> checkSdkVersion() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      sdkInt = androidInfo.version.sdkInt;
      manufacturer = androidInfo.manufacturer;
      return sdkInt <= 31 && !manufacturer.toLowerCase().contains('xiaomi');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Future<void> initSdk() async {
      await checkSdkVersion();
    }

    initSdk();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final themeProvider = context.watch<ThemeProvider>();
        final useDynamicColor = Platform.isAndroid &&
            themeProvider.useDynamicColor &&
            (sdkInt >= 31 ||
                (sdkInt == 31 &&
                    !manufacturer.toLowerCase().contains('xiaomi')));

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
            fontFamily: 'ProductSans',
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Lato'),
              bodyMedium: TextStyle(fontFamily: 'Lato'),
              bodySmall: TextStyle(fontFamily: 'Lato'),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            fontFamily: 'ProductSans',
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Lato'),
              bodyMedium: TextStyle(fontFamily: 'Lato'),
              bodySmall: TextStyle(fontFamily: 'Lato'),
            ),
          ),
          home: ConnectivityWrapper(
            child: const SelectionScreen(),
          ),
        );
      },
    );
  }
}
