import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:post_ace/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:post_ace/main.dart';

class ThemeSelection extends StatefulWidget {
  const ThemeSelection({super.key});

  @override
  State<ThemeSelection> createState() => _ThemeSelectionState();
}

class _ThemeSelectionState extends State<ThemeSelection> {
  final double titleSize = 30;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    final canUseDynamicColor = Platform.isAndroid &&
        (MyApp.sdkInt >= 31 ||
            (MyApp.sdkInt == 31 &&
                !MyApp.manufacturer.toLowerCase().contains('xiaomi')));

    return Scaffold(
      appBar: AppBar(
        title: Text('Theme',
            style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 25)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Center(
              child: Lottie.asset('assets/lottie/theme.json',
                  height: 300, width: 300),
            ),
            const SizedBox(height: 20),
            // Theme Mode
            Center(
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                      value: ThemeMode.system, label: Text('Auto')),
                  ButtonSegment<ThemeMode>(
                      value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {themeProvider.themeMode},
                onSelectionChanged: (Set<ThemeMode> selected) {
                  if (selected.isNotEmpty) {
                    themeProvider.setThemeMode(selected.first);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // Material Switch
            if (canUseDynamicColor) ...[
              SwitchListTile(
                title: const Text(
                  'Material Theme',
                  style: TextStyle(fontSize: 20),
                ),
                subtitle: const Text(
                  'Use wallpaper colors. \nOnly supports Android 12 and above.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: themeProvider.useDynamicColor,
                onChanged: (_) => themeProvider.toggleDynamicColor(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
