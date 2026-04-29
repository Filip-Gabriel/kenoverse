import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:kenoverse/screens/home_screen.dart';
import 'functionality/theme/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future <void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(Kenoverse());
}

class Kenoverse extends StatelessWidget {
  const Kenoverse({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: CustomTheme.lightTheme(),
      home: const HomeScreen(),
    );
  }
}
