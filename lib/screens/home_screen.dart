// The primary landing page of the application.
// Displays a personalized greeting, news carousel, featured albums,
// recently accessed songs, and recent releases.
import 'package:flutter/material.dart' hide SearchBar;
import 'package:kenoverse/widgets/album_card.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/screens/setting_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/functionality/news_model.dart';
import 'package:kenoverse/functionality/sync_service.dart';
import 'package:kenoverse/screens/all_albums_screen.dart';
import 'package:kenoverse/widgets/home_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Generates a time-based greeting for the user.
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 4) return 'It is time for thy sleep,';
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  /// Helper to build the profile avatar/login icon.
  Widget _buildProfileAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const SettingsDialog(),
        );
      },
      child: CircleAvatar(
        radius: AppConstants.radiusXL,
        backgroundColor: context.colorScheme.primaryContainer,
        child: Icon(
          FirebaseAuth.instance.currentUser == null ? Icons.login : Icons.person_outline,
          color: context.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Welcome Header Section ---
              if (user != null)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirestoreService().getUserStream(user.uid),
                  builder: (context, snapshot) {
                    String name = 'Keno';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      name = (snapshot.data!.data() as Map<String, dynamic>)['username'] ?? 'Keno';
                    }
                    return HomeWelcomeHeader(
                      greeting: _getGreeting(),
                      name: name,
                      profileAvatar: _buildProfileAvatar(context),
                    );
                  },
                )
              else
                HomeWelcomeHeader(
                  greeting: _getGreeting(),
                  name: 'Keno',
                  profileAvatar: _buildProfileAvatar(context),
                ),

              // --- 2. News Carousel Section ---
              StreamBuilder<QuerySnapshot>(
                stream: FirestoreService().newsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox();
                  }

                  var articles = snapshot.data!.docs.map((doc) => NewsArticle.fromFirestore(doc)).toList();
                  return NewsCarousel(articles: articles);
                },
              ),

              // --- 3. Main Content Container ---
              Container(
                width: double.infinity,
                padding: context.paddingVertical(AppConstants.spacingLG),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 3a. Albums Row ---
                    _buildSectionTitle(
                      context, 
                      'Albums', 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllAlbumsScreen())),
                    ),
                    context.gapMD,
                    SizedBox(
                      height: 140,
                      child: StreamBuilder<List<Song>>(
                        stream: context.read<SyncService>().getLocalSongsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(child: Text('No songs found', style: TextStyle(color: context.colorScheme.secondary)));
                          }
                          var songs = snapshot.data!;
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: context.paddingHorizontal(AppConstants.spacingLG),
                            itemCount: songs.length,
                            itemBuilder: (context, index) {
                              return AlbumCard(song: songs[index]);
                            },
                          );
                        },
                      ),
                    ),
                    
                    context.gapLG,
                    
                    // --- 3b. Recently Accessed Section ---
                    Padding(
                      padding: context.paddingHorizontal(AppConstants.spacingLG),
                      child: Text(
                        'Recently Accessed',
                        style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    context.gapSM,
                    StreamBuilder<QuerySnapshot>(
                      stream: FirestoreService().getHistoryStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox();
                        }
                        return RecentlyAccessedList(historyDocs: snapshot.data!.docs);
                      },
                    ),
                    
                    context.gapLG,
                    
                    // --- 3c. Recent Releases Section ---
                    Padding(
                      padding: context.paddingHorizontal(AppConstants.spacingLG),
                      child: Text(
                        'Recent Releases',
                        style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    context.gapSM,
                    StreamBuilder<List<Song>>(
                      stream: context.read<SyncService>().getLocalSongsStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();
                        
                        // Sort by timestamp/id for "recent" simulation locally, 
                        // or just show the last 10 added to the cache.
                        var songs = snapshot.data!.take(10).toList();
                        return Column(
                          children: songs.map((song) {
                            return RecentReleaseTile(song: song);
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build section titles with an optional "View All" arrow.
  Widget _buildSectionTitle(BuildContext context, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: context.paddingHorizontal(AppConstants.spacingLG),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward, size: 20, color: context.colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}
