import 'package:flutter/material.dart' hide SearchBar;
import 'package:kenoverse/screens/lyric_screen.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';
import 'package:kenoverse/functionality/ui_elements.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/auth_service.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';

import 'package:kenoverse/functionality/news_model.dart';
import 'package:kenoverse/screens/all_albums_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 4) return 'It is time for thy sleep,';
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: context.textTheme.bodyLarge?.copyWith(
                                color: context.colorScheme.secondary,
                              ),
                        ),
                        Text(
                          'Keno',
                          style: context.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        } else {
                          // Show logout confirmation
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Account'),
                              content: Text('Logged in as ${user.email}'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await AuthService().signOut();
                                    if (context.mounted) Navigator.pop(context);
                                    setState(() {}); // Refresh to show logged out state
                                  },
                                  child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: context.colorScheme.primaryContainer,
                        child: Icon(
                          FirebaseAuth.instance.currentUser == null ? Icons.login : Icons.person_outline,
                          color: context.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Featured/Hero News Section (Carousel)
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

                  return SizedBox(
                    height: 220,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.98),
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                          child: News().newNews(context, articles[index]),
                        );
                      },
                    ),
                  );
                },
              ),

              // 3. Albums Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AllAlbumsScreen()),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Albums',
                              style: context.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: context.colorScheme.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    context.gapMD,
                    SizedBox(
                      height: 140,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirestoreService().songs,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                'No songs found',
                                style: TextStyle(color: context.colorScheme.secondary),
                              ),
                            );
                          }
                          var docs = snapshot.data!.docs;
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              var data = docs[index].data() as Map<String, dynamic>;
                              Song song = Song.fromFirestore(data, docs[index].id);
                              return Albums().newAlbum(context, song);
                            },
                          );
                        },
                      ),
                    ),
                    
                    context.gapLG,
                    
                    // 4. Recently Accessed Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Text(
                        'Recently Accessed',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    context.gapSM,
                    SizedBox(
                      height: 120,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirestoreService().getHistoryStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const SizedBox();
                          }
                          var historyDocs = snapshot.data!.docs;
                          
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: historyDocs.length,
                            itemBuilder: (context, index) {
                              String songId = historyDocs[index]['songId'];
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirestoreService().songsCollection.doc(songId).get(),
                                builder: (context, songSnapshot) {
                                  if (!songSnapshot.hasData || !songSnapshot.data!.exists) {
                                    return const SizedBox();
                                  }
                                  var data = songSnapshot.data!.data() as Map<String, dynamic>;
                                  Song song = Song.fromFirestore(data, songSnapshot.data!.id);
                                  return _buildRecentlyAccessedAlbum(context, song);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    
                    context.gapLG,
                    
                    // 5. Recent Releases List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Text(
                        'Recent Releases',
                        style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    context.gapSM,
                    StreamBuilder<QuerySnapshot>(
                      stream: FirestoreService().recentSongs,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox();
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox();
                        }
                        var docs = snapshot.data!.docs;
                        return Column(
                          children: docs.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            Song song = Song.fromFirestore(data, doc.id);
                            return _buildRecentSongTile(context, song);
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
      bottomNavigationBar: BottomBar.bottomAppBar(context),
    );
  }

  Widget _buildRecentlyAccessedAlbum(BuildContext context, Song song) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LyricScreen(song: song),
          ),
        );
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: context.radiusMD,
              child: Image(
                image: song.thumbnail()!.image,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            context.gapXS,
            Text(
              song.title(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSongTile(BuildContext context, Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LyricScreen(song: song),
            ),
          );
        },
        borderRadius: context.radiusLG,
        child: Container(
          padding: context.paddingMD,
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: context.radiusLG,
            border: Border.all(color: context.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: context.radiusMD,
                child: Image(
                  image: song.thumbnail()!.image,
                  height: 56,
                  width: 56,
                  fit: BoxFit.cover,
                ),
              ),
              context.gapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title(),
                      style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      song.songAlbums.isNotEmpty ? song.songAlbums.join(', ') : 'Single',
                      style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_vert,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
