import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/artist_model.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';

import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/screens/lyric_screen.dart';

class ArtistProfileScreen extends StatefulWidget {
  final String artistId;
  const ArtistProfileScreen({super.key, required this.artistId});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _showEditDialog(Artist artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _ArtistEditScreen(
          artist: artist,
          firestoreService: _firestoreService,
        ),
      ),
    );
  }

  void _claimProfile(Artist artist) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to claim a profile')));
      return;
    }

    Artist updated = Artist(
      id: artist.id,
      name: artist.name,
      bio: artist.bio,
      profileImageUrl: artist.profileImageUrl,
      socialMedia: artist.socialMedia,
      claimedBy: currentUser!.uid,
    );
    await _firestoreService.updateArtist(updated);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile claimed successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.getArtistStream(widget.artistId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!snapshot.data!.exists) return const Scaffold(body: Center(child: Text('Artist not found')));

        Artist artist = Artist.fromFirestore(snapshot.data!);
        bool canEdit = artist.claimedBy == currentUser?.uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(artist.name),
            actions: [
              if (canEdit)
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showEditDialog(artist))
              else if (artist.claimedBy == null && currentUser != null)
                TextButton(onPressed: () => _claimProfile(artist), child: const Text('Claim Profile')),
            ],
          ),
          body: SingleChildScrollView(
            padding: context.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: artist.profileImageUrl != null ? NetworkImage(artist.profileImageUrl!) : null,
                  child: artist.profileImageUrl == null ? const Icon(Icons.person, size: 60) : null,
                ),
                context.gapLG,
                Text(artist.name, style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                context.gapLG,
                const Divider(),
                context.gapMD,
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('BIO', style: context.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: context.colorScheme.secondary)),
                ),
                context.gapSM,
                Text(artist.bio ?? 'No bio available yet.', style: const TextStyle(fontSize: 16, height: 1.5)),
                context.gapXL,
                if (artist.socialMedia != null && artist.socialMedia!.values.any((v) => v.isNotEmpty)) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('LINKS', style: context.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: context.colorScheme.secondary)),
                  ),
                  context.gapSM,
                  ...artist.socialMedia!.entries.where((e) => e.value.isNotEmpty).map((e) => ListTile(
                    leading: Icon(e.key == 'twitter' ? Icons.link : Icons.open_in_new),
                    title: Text(e.key.toUpperCase()),
                    subtitle: Text(e.value),
                    onTap: () {}, // TODO: Launch URL
                  )),
                ],
                context.gapXL,
                _buildSongList(artist),
              ],
            ),
          ),
          bottomNavigationBar: BottomBar.bottomAppBar(context),
        );
      },
    );
  }

  Widget _buildSongList(Artist artist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORKS',
          style: context.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: context.colorScheme.secondary,
          ),
        ),
        context.gapSM,
        StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getSongsByArtist(artist.name),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No songs found for this artist.'),
              );
            }

            var songs = snapshot.data!.docs.map((doc) {
              return Song.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final roles = _getArtistRoles(song, artist.name);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: context.radiusSM,
                    child: Image(
                      image: song.thumbnail()!.image,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(song.title(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(roles.join(', ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LyricScreen(song: song)),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  List<String> _getArtistRoles(Song song, String name) {
    List<String> roles = [];
    String n = name.toLowerCase().trim();
    
    if (song.originalArtists.any((s) => s.toLowerCase().trim() == n)) roles.add('Original Artist');
    if (song.vocals.any((s) => s.toLowerCase().trim() == n)) roles.add('Vocals');
    if (song.featuredArtists.any((s) => s.toLowerCase().trim() == n)) roles.add('Featured');
    if (song.audioPreedit.any((s) => s.toLowerCase().trim() == n)) roles.add('Audio/Mix');
    if (song.arrangement.any((s) => s.toLowerCase().trim() == n)) roles.add('Arrangement');
    if (song.artworkBy.any((s) => s.toLowerCase().trim() == n)) roles.add('Artwork');
    if (song.videoBy.any((s) => s.toLowerCase().trim() == n)) roles.add('Video');
    
    return roles;
  }
}

class _ArtistEditScreen extends StatefulWidget {
  final Artist artist;
  final FirestoreService firestoreService;

  const _ArtistEditScreen({required this.artist, required this.firestoreService});

  @override
  State<_ArtistEditScreen> createState() => _ArtistEditScreenState();
}

class _ArtistEditScreenState extends State<_ArtistEditScreen> {
  late TextEditingController bioController;
  late TextEditingController twitterController;
  late TextEditingController spotifyController;
  late TextEditingController imgController;

  @override
  void initState() {
    super.initState();
    bioController = TextEditingController(text: widget.artist.bio);
    twitterController = TextEditingController(text: widget.artist.socialMedia?['twitter']);
    spotifyController = TextEditingController(text: widget.artist.socialMedia?['spotify']);
    imgController = TextEditingController(text: widget.artist.profileImageUrl);
  }

  @override
  void dispose() {
    bioController.dispose();
    twitterController.dispose();
    spotifyController.dispose();
    imgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile: ${widget.artist.name}'),
        actions: [
          TextButton(
            onPressed: () async {
              Artist updated = Artist(
                id: widget.artist.id,
                name: widget.artist.name,
                bio: bioController.text,
                profileImageUrl: imgController.text,
                socialMedia: {
                  'twitter': twitterController.text,
                  'spotify': spotifyController.text,
                },
                claimedBy: widget.artist.claimedBy,
              );
              await widget.firestoreService.updateArtist(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: context.paddingLG,
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: imgController.text.isNotEmpty ? NetworkImage(imgController.text) : null,
                child: imgController.text.isEmpty ? const Icon(Icons.person, size: 60) : null,
              ),
            ),
            context.gapLG,
            TextField(
              controller: imgController,
              decoration: const InputDecoration(labelText: 'Profile Image URL', border: OutlineInputBorder()),
              onChanged: (val) => setState(() {}),
            ),
            context.gapMD,
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
              maxLines: 5,
            ),
            context.gapMD,
            TextField(
              controller: twitterController,
              decoration: const InputDecoration(labelText: 'Twitter/X URL', border: OutlineInputBorder()),
            ),
            context.gapMD,
            TextField(
              controller: spotifyController,
              decoration: const InputDecoration(labelText: 'Spotify Artist URL', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}
