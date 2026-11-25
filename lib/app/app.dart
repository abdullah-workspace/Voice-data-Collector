import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hearassist_data_collector/app/theme/app_theme.dart';
import 'package:hearassist_data_collector/providers/recording_provider.dart';
import 'package:hearassist_data_collector/providers/dataset_provider.dart';
import 'package:hearassist_data_collector/providers/settings_provider.dart';
import 'package:hearassist_data_collector/screens/home_screen.dart';

/// Root widget for the HearAssist Data Collector application.
class HearAssistApp extends StatelessWidget {
  const HearAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecordingProvider()),
        ChangeNotifierProvider(create: (_) => DatasetProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'HearAssist Data Collector',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light, // Default theme explicitly set to Light
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
