import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'functionality/theme/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:kenoverse/functionality/auth_check.dart';
import 'package:provider/provider.dart';
import 'package:kenoverse/functionality/theme/theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const Kenoverse(),
    ),
  );
}

class Kenoverse extends StatelessWidget {
  const Kenoverse({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: CustomTheme.lightTheme(),
      darkTheme: CustomTheme.darkTheme(),
      themeMode: Provider.of<ThemeNotifier>(context).themeMode,
      home: AuthCheck(),
    );
  }
}
// todo make it so that the app will download song and update its internal database from firebase when it connects to the internet