import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/article_model.dart';
import 'package:kricket_pk/models/match_model.dart';
import 'package:kricket_pk/services/matches_api.dart';
import 'package:kricket_pk/screens/match_detail_screen.dart';
import 'package:kricket_pk/widgets/net_image.dart';
import 'package:kricket_pk/widgets/section_title.dart';
import 'package:kricket_pk/widgets/news_widgets.dart';
import 'package:kricket_pk/screens/article_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.articles, this.onTabChange});
  final List<ArticleData> articles;
  final ValueChanged<int>? onTabChange;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllNews = false;

  @override
  Widget build(BuildContext context) {
    final topStory = widget.articles.first;
    final newsItems = _showAllNews ? widget.articles : widget.articles.take(3).toList();
    final trending = (widget.articles.length > 3 ? widget.articles.skip(3) : widget.articles.skip(1)).take(4).toList();

    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 16, bottom: 32 + safeBottom + 72),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome to Kricket.pk', style: TextStyle(color: K.dark, fontSize: 24, height: 1.33, fontWeight: FontWeight.w700, letterSpacing: -.6)),
              Text('Stay updated with the latest cricket news.', style: TextStyle(color: K.body, fontSize: 16, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FutureBuilder<MatchesResponse>(
            future: MatchesApi().getFixtures(limit: 1, page: 1),
            builder: (context, snapshot) {
              final match = snapshot.data?.matches.firstOrNull;
              final team1 = match?.team1Name ?? 'Pakistan';
              final team2 = match?.team2Name ?? 'West Indies';
              final format = match?.format ?? 'T20';
              final ground = match?.groundName ?? 'Gaddafi Stadium, Lahore';

              return InkWell(
                onTap: () {
                  if (match != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MatchDetailScreen(matchNo: match.matchNo, initialMatch: match),
                      ),
                    );
                  } else {
                    widget.onTabChange?.call(2);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: K.green,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14004D2C), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: K.lime, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'FEATURED MATCH — ${team1.toUpperCase()} VS ${team2.toUpperCase()}',
                                    style: const TextStyle(color: Color(0xFF7BBD93), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .6),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$team1 vs $team2',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$format • $ground',
                              style: const TextStyle(color: Color(0xCC7BBD93), fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: K.lime,
                          foregroundColor: K.limeText,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          if (match != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MatchDetailScreen(matchNo: match.matchNo, initialMatch: match),
                              ),
                            );
                          } else {
                            widget.onTabChange?.call(2);
                          }
                        },
                        child: const Text('VIEW MATCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () => openArticle(context, topStory, widget.articles),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        NetImage(topStory.image, height: 191, width: double.infinity),
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            color: const Color(0xFFDC3545),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: const Text('TOP STORY', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topStory.title, style: const TextStyle(color: K.dark, fontSize: 24, height: 1.25, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(topStory.summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: K.body, fontSize: 16, height: 1.5)),
                          const SizedBox(height: 12),
                          const Text('READ MORE', style: TextStyle(color: K.limeText, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        QuickActions(onTabChange: widget.onTabChange),
        SectionTitle(
          title: 'Cricket News',
          action: _showAllNews ? 'SHOW LESS' : 'SEE ALL',
          onActionTap: () => setState(() => _showAllNews = !_showAllNews),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              for (var i = 0; i < newsItems.length; i++) ...[
                NewsRow(article: newsItems[i], articles: widget.articles),
                if (i != newsItems.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),

        // Widget leading to News Page when expanded
        if (_showAllNews) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: InkWell(
              onTap: () => widget.onTabChange?.call(1),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: K.dark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: K.green, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A004D2C), blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF003820),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.newspaper, color: K.lime, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore All News Articles',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Browse full archive of 3,500+ news & analysis',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: K.lime, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        SectionTitle(
          title: 'Trending Stories',
          action: widget.onTabChange != null ? 'SEE ALL' : '',
          onActionTap: () => widget.onTabChange?.call(1),
        ),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemBuilder: (context, index) => TrendCard(article: trending[index], articles: widget.articles),
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: trending.length,
          ),
        ),
      ]),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, this.onTabChange});
  final ValueChanged<int>? onTabChange;

  @override
  Widget build(BuildContext context) {
    const data = [
      (Icons.newspaper, 'Cricket News', 1),
      (Icons.sports_cricket, 'Latest\nMatches', 2),
      (Icons.emoji_events, 'Tournaments', 3),
      (Icons.groups, 'Trending\nPlayers', 4),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < data.length; i++)
            InkWell(
              onTap: () => onTabChange?.call(data[i].$3),
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: i == 0 ? K.lime : const Color(0xFFE8E8E8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(data[i].$1, size: 20, color: K.dark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data[i].$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, height: 1.27, color: K.ink),
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
