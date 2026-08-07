import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/article_model.dart';
import 'package:kricket_pk/services/news_api.dart';
import 'package:kricket_pk/widgets/api_error_view.dart';
import 'package:kricket_pk/screens/home_screen.dart';
import 'package:kricket_pk/screens/matches_screen.dart';
import 'package:kricket_pk/screens/tournaments_screen.dart';
import 'package:kricket_pk/screens/news_screen.dart';
import 'package:kricket_pk/screens/placeholder_screen.dart';

void main() => runApp(const KricketApp());

class KricketApp extends StatelessWidget {
  const KricketApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kricket.pk',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: K.bg,
          colorScheme: ColorScheme.fromSeed(seedColor: K.green),
          fontFamily: 'Inter',
        ),
        home: const AppShell(),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int page = 0;
  late final Future<List<ArticleData>> articles;

  @override
  void initState() {
    super.initState();
    articles = const KricketNewsApi()
        .getPaginatedArticles(page: 1, perPage: 16)
        .then((res) => res.articles);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: page < 4 ? const KricketBar() : null,
        body: FutureBuilder<List<ArticleData>>(
          future: articles,
          builder: (context, snapshot) {
            if (snapshot.hasError) return ApiErrorView(error: snapshot.error!);
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: K.green));
            return IndexedStack(
              index: page,
              children: [
                HomeScreen(
                  articles: snapshot.data!,
                  onTabChange: (i) => setState(() => page = i),
                ),
                NewsScreen(articles: snapshot.data!),
                const MatchesScreen(),
                const TournamentsScreen(),
                const PlaceholderScreen(),
              ],
            );
          },
        ),
        bottomNavigationBar: KricketNav(index: page, onTap: (i) => setState(() => page = i)),
      );
}

class KricketBar extends StatelessWidget implements PreferredSizeWidget {
  const KricketBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => AppBar(
        toolbarHeight: 64,
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        leading: const Icon(Icons.menu, size: 20),
        titleSpacing: 0,
        title: const Text('Kricket.pk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        actions: const [Icon(Icons.search, size: 20), SizedBox(width: 16), Icon(Icons.notifications_none, size: 21), SizedBox(width: 16)],
      );
}

class KricketNav extends StatelessWidget {
  const KricketNav({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;
  static const items = [
    (Icons.home, 'Home'),
    (Icons.newspaper, 'News'),
    (Icons.sports_cricket, 'Matches'),
    (Icons.emoji_events, 'Tournaments'),
    (Icons.groups, 'Players'),
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFBFC9BF))),
            boxShadow: [BoxShadow(color: Color(0x14004D2C), blurRadius: 10, offset: Offset(0, -4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(horizontal: i == index ? 16 : 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: i == index ? K.lime : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i].$1, size: 20, color: i == index ? K.limeText : K.body),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          style: TextStyle(
                            fontSize: 11,
                            color: i == index ? K.limeText : K.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
