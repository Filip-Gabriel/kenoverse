import 'package:flutter/material.dart' hide SearchBar;
import 'package:kenoverse/functionality/bottom_app_bar.dart';
import 'package:kenoverse/functionality/ui_elements.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return
      SafeArea(child: Scaffold(
      body: SearchBar(
        child: Scaffold(
          body: ListView(
            children: [
              // Use the SearchBar widget and pass the News container as its child
              News().newNews(
                'BREAKING NEWS',
                Image.asset('images/callofsilence.jpg'),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              'Albums',
                              style: TextStyle(color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Icon(Icons.arrow_forward),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Albums().newAlbum(
                            'album 1',
                            Image.asset('images/callofsilence.jpg'),
                          ),
                          Albums().newAlbum(
                            'album 2',
                            Image.asset('images/callofsilence.jpg'),
                          ),
                          Albums().newAlbum(
                            'album 3',
                            Image.asset('images/callofsilence.jpg'),
                          ),
                          Albums().newAlbum(
                            'album 4',
                            Image.asset('images/callofsilence.jpg'),
                          ),
                          Albums().newAlbum(
                            'album 5',
                            Image.asset('images/callofsilence.jpg'),
                          ),
                          Albums().newAlbum(
                            'album 6',
                            Image.asset('images/callofsilence.jpg'),
                          ),
                          Albums().newAlbum(
                            'album 7',
                            Image.asset('images/callofsilence.jpg'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar.bottomAppBar(),
    ),);
  }
}
