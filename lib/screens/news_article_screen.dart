// Displays the full content of a news article.
// Features a large header image and formatted text for the article body.
import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/news_model.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:intl/intl.dart';

class NewsArticleScreen extends StatelessWidget {
  final NewsArticle article;
  const NewsArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'images/callofsilence.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: context.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  context.gapSM,
                  Text(
                    DateFormat('MMMM d, yyyy').format(article.timestamp),
                    style: context.textTheme.labelMedium?.copyWith(color: context.colorScheme.secondary),
                  ),
                  context.gapLG,
                  const Divider(),
                  context.gapLG,
                  Text(
                    article.content,
                    style: context.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                  context.gapXXL,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
