import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'functionality/theme/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:kenoverse/functionality/auth_check.dart';
import 'package:provider/provider.dart';
import 'package:kenoverse/functionality/theme/theme_notifier.dart';
import 'package:kenoverse/functionality/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final syncService = SyncService();
  await syncService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        Provider.value(value: syncService),
      ],
      child: const Kenoverse(),
    ),
  );
}

class Kenoverse extends StatelessWidget {
  const Kenoverse({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CustomTheme.lightTheme(),
      darkTheme: CustomTheme.darkTheme(),
      themeMode: Provider.of<ThemeNotifier>(context).themeMode,
      home: const AuthCheck(),
    );
  }
}