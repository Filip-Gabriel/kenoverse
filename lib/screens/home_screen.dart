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
    return SafeArea(
      child: Scaffold(
        body: ListView(
          children: [
            // Wrap News in KenoSearchBar so it can also trigger the sheet
            KenoSearchBar(
              child: News().newNews(
                'BREAKING NEWS',
                Image.asset('images/callofsilence.jpg'),
              ),
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
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Albums',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
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
        bottomNavigationBar: BottomBar.bottomAppBar(context),
      ),
    );
  }
}
