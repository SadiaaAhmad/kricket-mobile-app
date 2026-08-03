import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/article_model.dart';
import 'package:kricket_pk/widgets/net_image.dart';
import 'package:kricket_pk/widgets/section_title.dart';
import 'package:kricket_pk/widgets/news_widgets.dart';
import 'package:kricket_pk/screens/article_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, required this.articles});
  final List<ArticleData> articles;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _showAllNews = false;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final displayedArticles = _showAllNews ? widget.articles : widget.articles.take(3).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 32 + safeBottom + 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                chip('All', true),
                chip('Pakistan'),
                chip('International'),
                chip('Domestic'),
                chip('PSL'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => openArticle(context, widget.articles[0], widget.articles),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    NetImage(widget.articles[0].image, width: double.infinity, height: 202),
                    Container(
                      height: 202,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xD9001C10)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.articles[0].title,
                            style: const TextStyle(color: Colors.white, fontSize: 23, height: 1.15, fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.articles[0].summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SectionTitle(
            title: 'Latest News',
            action: _showAllNews ? 'SHOW LESS ‹' : 'VIEW ALL ›',
            onActionTap: () => setState(() => _showAllNews = !_showAllNews),
          ),
          for (var article in displayedArticles) NewsListCard(article: article, articles: widget.articles),
          const SectionTitle(title: 'Trending Stories', action: ''),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final article in widget.articles.skip(1)) ...[
                  RealTrendWide(article: article, articles: widget.articles),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget chip(String t, [bool active = false]) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? K.lime : const Color(0xFFF0F1F0),
          border: active ? null : Border.all(color: const Color(0xFFCBD0CB)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          t,
          style: TextStyle(color: active ? K.limeText : K.body, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}
