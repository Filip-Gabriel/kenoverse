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
//todo make it so that when clicking the album title/icon of the sideways listview in the homescreen, it opens up a newpage where all albums are shown(the new screen should include the kenoappbar)
//todo when searching something in the kenosearchbar, it shows previews of what you might be looking for and once you click enter, you get redirected to a new page that shows all results(it should have the kenoappbar)(it should search everything, from release date, to lyrics, to artist, to the artists credited. it should only show the card of the songs, not details(like the recent releases section from the homescreen))
//todo add a recently accesed section(sideways listview) in the homescreen that will display the last 10 songs the user has accesed
// todo expand the settings menu
//todo add karaoke function