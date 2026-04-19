import 'package:flutter/material.dart';
import 'dart:ui';

class News {
  Container newNews(String title, Image thumbnail) {
    return Container(
      clipBehavior: Clip.antiAlias, // Required to clip image to borderRadius
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            offset: Offset(4.0, 4.0),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: thumbnail.image, fit: BoxFit.cover),
          Positioned(
            bottom: 20,
            left: 20,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Albums {
  Container newAlbum(String title, Image thumbnail) {
    return Container(
      padding: const EdgeInsets.all(10),
      clipBehavior: Clip.antiAlias,
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        // color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: thumbnail.image, fit: BoxFit.cover),
          Positioned(
            bottom: 20,
            left: 20,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  final Widget child;
  const SearchBar({super.key, required this.child});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  bool _isSearchVisible = false;

  void toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: toggleSearch,
          child: widget.child,
        ),
        if (_isSearchVisible)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        if (_isSearchVisible)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withAlpha(230),
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: toggleSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// class MiniAlbumViewer extends StatefulWidget {
//   const MiniAlbumViewer({super.key});
//   @override
//   State<MiniAlbumViewer> createState() => _MiniAlbumViewerState();
//
//   class _MiniAlbumViewerState extends State<MiniAlbumViewer> {
//
// }
// }
