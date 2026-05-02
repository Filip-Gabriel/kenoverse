import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/ui_elements.dart';
import 'package:kenoverse/screens/new_song_screen.dart';
import 'package:kenoverse/screens/home_screen.dart';
import 'package:kenoverse/screens/setting_screen.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';

class BottomBar {
  static BottomAppBar bottomAppBar(BuildContext context) {
    return BottomAppBar(
      height: AppConstants.bottomNavHeight,
      padding: EdgeInsets.zero,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                KenoSearchBar.open(context);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingScreen()),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewSong()),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
    );
  }
}
