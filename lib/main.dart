import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'services/ephemeris_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Extract bundled .se1 ephemeris assets and point libswe at them.
  // This is a no-op on subsequent launches for files already extracted.
  try {
    await EphemerisService.instance.initialize();
  } catch (e) {
    debugPrint('[Ephemeris] Initialisation failed: $e');
  }

  runApp(
    const ProviderScope(child: AstroPortableApp()),
  );
}

class AstroPortableApp extends StatelessWidget {
  const AstroPortableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astro Portable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF224466),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF060F18),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
