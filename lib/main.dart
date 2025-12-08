import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/hub/hub_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: PyrealHubApp(),
    ),
  );
}

class PyrealHubApp extends StatelessWidget {
  const PyrealHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // To use a custom font in the future, set fontFamily to your font name and add assets in pubspec.yaml
    // Example:
    // theme: ThemeData(
    //   fontFamily: 'Roboto',
    //   ...existing code...
    // )
    // For now, use system font:
    return MaterialApp(
      title: 'Pyreal Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        fontFamily: null, // System font. Change to e.g. 'Roboto' to use a custom font.
      ),
      home: const HubScreen(),
    );
  }
}
