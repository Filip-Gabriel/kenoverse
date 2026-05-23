// A card widget used on the Home Screen to display news article previews.
// Includes a title, background image with gradient overlay, and navigation to details.
import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/news_model.dart';
import 'package:kenoverse/screens/news_article_screen.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/functionality/lyrics.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;

  const NewsCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsArticleScreen(article: article)),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: context.colorScheme.outlineVariant),
          color: context.colorScheme.secondaryContainer,
          borderRadius: context.radiusXL,
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withValues(alpha: 0.2),
              offset: const Offset(4.0, 4.0),
              blurRadius: 10.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              article.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Song.defaultThumbnail,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: AppConstants.spacingMD,
              left: AppConstants.spacingMD,
              right: AppConstants.spacingMD,
              child: Text(
                article.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
