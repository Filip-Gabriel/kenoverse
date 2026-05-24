// The shell widget that manages top-level navigation.
// Switches between Home, Playlists, Gallery, and Upload screens.
// Adapts its layout for mobile (BottomNavigationBar) and desktop (NavigationRail).
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';
import 'package:kenoverse/widgets/keno_search_bar.dart';
import 'package:kenoverse/screens/artworks_screen.dart';
import 'package:kenoverse/screens/home_screen.dart';
import 'package:kenoverse/screens/new_song_screen.dart';
import 'package:kenoverse/screens/playlist_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PlaylistScreen(),
    const ArtworksScreen(),
    const NewSong(),
  ];

  bool _shouldShowPCUI(BuildContext context) {
    // If the screen is narrow (mobile or small window), always show mobile UI
    if (MediaQuery.of(context).size.width <= AppConstants.breakpointMobile) {
      return false;
    }
    
    // On Web or Desktop platforms, if screen is wide enough, show PC UI
    if (kIsWeb) return true;
    
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return true;
    } catch (_) {
      // If Platform check fails (some web edge cases), fallback to width only
    }

    // Default for tablets/large screens on mobile OS
    return MediaQuery.of(context).size.width > AppConstants.breakpointMobile;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isPC = _shouldShowPCUI(context);

    return Scaffold(
      body: Row(
        children: [
          if (isPC)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              leading: Column(
                children: [
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => KenoSearchBar.open(context),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.playlist_play_outlined),
                  selectedIcon: Icon(Icons.playlist_play),
                  label: Text('Playlists'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.image_outlined),
                  selectedIcon: Icon(Icons.image),
                  label: Text('Gallery'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon: Icon(Icons.add_circle),
                  label: Text('Upload'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isPC
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.playlist_play),
                  label: 'Playlists',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.image_outlined),
                  label: 'Gallery',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  label: 'Upload',
                ),
              ],
            ),
      floatingActionButton: !isPC && _selectedIndex != 3 // Don't show search FAB on Upload tab if redundant
          ? FloatingActionButton(
              onPressed: () => KenoSearchBar.open(context),
              child: const Icon(Icons.search),
            )
          : null,
    );
  }
}
