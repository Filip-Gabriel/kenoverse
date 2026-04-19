import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:kenoverse/screens/home_screen.dart';
import 'functionality/theme.dart';

void main() {
  runApp(Kenoverse());
}

class Kenoverse extends StatelessWidget {
  const Kenoverse({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: CustomTheme.lightTheme(),
      home: HomeScreen(),

    );
  }
}
