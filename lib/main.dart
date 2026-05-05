import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:kenoverse/screens/home_screen.dart';
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
//todo expand the settings menu
//todo move the settings menu to the profile icon one
//todo remove the disabled textfield that shows the users username(replace it with something more aestethically pleasing)
//todo once a user signs up, they get assigned an id that will show under their username, ever so slightly dimmed. it should be formatted like "Nekovert #(the next number from the one of the one before him.)"
//todo add karaoke function(the user will hit the play button which will start a timer, and based on how the lyrics are configured to the timestamp, the current ones will get highlighted, while the others will be dimmed)
//todo expand karaoke function. you can now link an audio file to a song and once you hit play, the respective audio track will also start playing
//todo expand karaoke function. add youtube preview and make it so that you can play the youtube mv in a popup in the app
//allabumscreen: remove the bottom bar an replace with top appbar?
//allabumscreen: wrap it in a safe area?
