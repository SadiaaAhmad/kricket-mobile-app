import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/article_model.dart';
import 'package:kricket_pk/services/news_api.dart';
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
  String _selectedCategory = 'All';
  bool _showAllNews = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 196;
  final List<ArticleData> _dynamicArticles = [];

  @override
  void initState() {
    super.initState();
    _dynamicArticles.addAll(widget.articles);
    _fetchPage(1);
  }

  Future<void> _fetchPage(int page) async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await const KricketNewsApi().getPaginatedArticles(
        page: page,
        perPage: 16,
      );

      if (mounted) {
        setState(() {
          if (page == 1) {
            _dynamicArticles.clear();
            _dynamicArticles.addAll(result.articles.isNotEmpty ? result.articles : widget.articles);
          } else {
            _dynamicArticles.addAll(result.articles);
          }
          _currentPage = result.currentPage;
          _totalPages = result.totalPages;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    final baseList = _dynamicArticles.isNotEmpty ? _dynamicArticles : widget.articles;

    // Filter articles based on selected category chip
    final filteredArticles = _selectedCategory == 'All'
        ? baseList
        : baseList.where((a) =>
            a.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
            (_selectedCategory == 'PSL' && (a.title.contains('PSL') || a.summary.contains('PSL')))).toList();

    final articlesList = filteredArticles.isNotEmpty ? filteredArticles : baseList;
    final topStory = articlesList.first;
    final newsItems = _showAllNews ? articlesList : articlesList.take(4).toList();
    final trending = (articlesList.length > 4 ? articlesList.skip(4) : articlesList.skip(1)).toList();

    return Scaffold(
      backgroundColor: K.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: 12, bottom: 24 + safeBottom + 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter Chips Bar
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  _buildChip('All'),
                  _buildChip('Pakistan'),
                  _buildChip('International'),
                  _buildChip('Domestic'),
                  _buildChip('PSL'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Top Featured Story Banner Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => openArticle(context, topStory, baseList),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        NetImage(topStory.image, width: double.infinity, height: 210),
                        Container(
                          height: 210,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xF0001C10)],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: K.lime,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'TOP STORY',
                              style: TextStyle(color: K.limeText, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topStory.title,
                                style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.2, fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(topStory.category, style: const TextStyle(color: K.lime, fontSize: 11, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 8),
                                  const Text('•', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${topStory.date} • ${topStory.readTime}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Latest News Section Title & Toggle
            SectionTitle(
              title: 'Latest News',
              action: _showAllNews ? 'SHOW LESS' : 'SEE ALL',
              onActionTap: () {
                setState(() {
                  _showAllNews = !_showAllNews;
                });
              },
            ),

            // News Items List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (var article in newsItems)
                    NewsListCard(article: article, articles: baseList),
                ],
              ),
            ),

            // SEE MORE / LOAD MORE ARTICLES BUTTON when expanded
            if (_showAllNews) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isLoadingMore || _currentPage >= _totalPages)
                        ? null
                        : () => _fetchPage(_currentPage + 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: K.dark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _currentPage >= _totalPages
                                ? 'ALL ARTICLES LOADED'
                                : 'SEE MORE ARTICLES',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .5),
                          ),
                  ),
                ),
              ),
            ],

            if (!_showAllNews && trending.isNotEmpty) ...[
              const SectionTitle(title: 'Trending Stories', action: ''),
              SizedBox(
                height: 156,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: trending.length,
                  itemBuilder: (context, index) {
                    final article = trending[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: RealTrendWide(article: article, articles: baseList),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String title) {
    final active = _selectedCategory == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? K.lime : Colors.white,
          border: active ? null : Border.all(color: const Color(0xFFCBD0CB)),
          borderRadius: BorderRadius.circular(22),
          boxShadow: active
              ? const [BoxShadow(color: Color(0x14004D2C), blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? K.limeText : K.body,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
