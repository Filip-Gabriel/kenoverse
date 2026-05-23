// A community gallery for viewing and submitting fanart.
// Displays artworks in a responsive grid and provides a full-screen viewer.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/functionality/fanart_model.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArtworksScreen extends StatefulWidget {
  const ArtworksScreen({super.key});

  @override
  State<ArtworksScreen> createState() => _ArtworksScreenState();
}

class _ArtworksScreenState extends State<ArtworksScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  void _showUploadDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to upload fanart')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FanartUploadScreen(
          currentUser: user,
          firestoreService: _firestoreService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Gallery'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.fanartStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.palette_outlined, size: 60, color: Colors.grey),
                  context.gapMD,
                  const Text('No fanart yet. Be the first to submit!'),
                  context.gapMD,
                  ElevatedButton(onPressed: _showUploadDialog, child: const Text('Submit Art')),
                ],
              ),
            );
          }

          var fanarts = snapshot.data!.docs.map((doc) => Fanart.fromFirestore(doc)).toList();

          return GridView.builder(
            padding: context.paddingMD,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing: AppConstants.spacingSM,
              mainAxisSpacing: AppConstants.spacingSM,
              childAspectRatio: 0.8, // Slightly taller for credits
            ),
            itemCount: fanarts.length,
            itemBuilder: (context, index) {
              final art = fanarts[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: context.radiusMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Show full screen image
                          showDialog(
                            context: context,
                            builder: (context) => Dialog.fullscreen(
                              child: Stack(
                                children: [
                                  Center(child: Image.network(art.imageUrl)),
                                  Positioned(
                                    top: 40,
                                    right: 20,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Image.network(
                          art.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: context.paddingSM,
                      child: Text(
                        'by ${art.artistName ?? 'Anonymous'}',
                        style: context.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Submit Art'),
      ),
    );
  }
}

class _FanartUploadScreen extends StatefulWidget {
  final User currentUser;
  final FirestoreService firestoreService;

  const _FanartUploadScreen({required this.currentUser, required this.firestoreService});

  @override
  State<_FanartUploadScreen> createState() => _FanartUploadScreenState();
}

class _FanartUploadScreenState extends State<_FanartUploadScreen> {
  final urlController = TextEditingController();
  String _username = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() async {
    final name = await widget.firestoreService.getUsername(widget.currentUser.uid);
    if (mounted) {
      setState(() {
        _username = name ?? 'Anonymous';
      });
    }
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Fanart'),
        actions: [
          TextButton(
            onPressed: () async {
              if (urlController.text.isNotEmpty) {
                // Fetch the latest username to ensure it's accurate
                final username = await widget.firestoreService.getUsername(widget.currentUser.uid);
                
                final newArt = Fanart(
                  id: '',
                  imageUrl: urlController.text,
                  uploaderId: widget.currentUser.uid,
                  artistName: username ?? 'Anonymous',
                  timestamp: DateTime.now(),
                );
                await widget.firestoreService.addFanart(newArt);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: context.paddingLG,
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainer,
                borderRadius: context.radiusXL,
              ),
              child: urlController.text.isNotEmpty
                  ? ClipRRect(
                      borderRadius: context.radiusXL,
                      child: Image.network(
                        urlController.text,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                      ),
                    )
                  : const Icon(Icons.image_outlined, size: 50),
            ),
            context.gapLG,
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
              onChanged: (val) => setState(() {}),
            ),
            context.gapMD,
            Text(
              'Submission guidelines: This artwork will be posted under your account name ($_username).',
              style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
