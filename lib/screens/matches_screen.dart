import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/match_model.dart';
import 'package:kricket_pk/services/matches_api.dart';
import 'package:kricket_pk/widgets/match_widgets.dart';
import 'package:kricket_pk/screens/match_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;
  
  // Active page trackers
  int _fixturesPage = 1;
  int _resultsPage = 1;

  late Future<MatchesResponse> _fixturesFuture;
  late Future<MatchesResponse> _resultsFuture;

  final List<String> _categories = ['All', 'International', 'Domestic', 'PSL', 'Women'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // ignore: avoid_print
    print('[DEBUG MatchesScreen] Initializing MatchesScreen state...');
    _loadData();
  }

  void _loadData() {
    final api = MatchesApi();
    _fixturesFuture = api.getFixtures(limit: 10, page: _fixturesPage);
    _resultsFuture = api.getResults(limit: 10, page: _resultsPage);
  }

  void _changeFixturesPage(int page) {
    setState(() {
      _fixturesPage = page;
      // ignore: avoid_print
      print('[DEBUG MatchesScreen] Navigating Fixtures to Page $page');
      _fixturesFuture = MatchesApi().getFixtures(limit: 10, page: page);
    });
  }

  void _changeResultsPage(int page) {
    setState(() {
      _resultsPage = page;
      // ignore: avoid_print
      print('[DEBUG MatchesScreen] Navigating Results to Page $page');
      _resultsFuture = MatchesApi().getResults(limit: 10, page: page);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: K.dark,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text('Matches', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5)),
        actions: const [
          Icon(Icons.search, size: 20, color: Colors.white),
          SizedBox(width: 14),
          Icon(Icons.notifications_none, size: 20, color: Colors.white),
          SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: K.dark,
              unselectedLabelColor: K.body,
              indicatorColor: K.lime,
              indicatorWeight: 3.5,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'LIVE'),
                Tab(text: 'Fixtures'),
                Tab(text: 'Results'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category Filters Row
          Container(
            height: 48,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final active = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? K.dark : const Color(0xFFF0F2F0),
                      borderRadius: BorderRadius.circular(20),
                      border: active ? null : Border.all(color: const Color(0xFFDCDFDB)),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: active ? K.lime : K.body,
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8ECE8)),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Live Matches Tab View
                _LiveMatchesView(selectedCategory: _categories[_selectedCategoryIndex]),
                // Fixtures Tab View
                _MatchesListView(
                  responseFuture: _fixturesFuture,
                  selectedCategory: _categories[_selectedCategoryIndex],
                  currentPage: _fixturesPage,
                  onPageChanged: _changeFixturesPage,
                ),
                // Results Tab View
                _MatchesListView(
                  responseFuture: _resultsFuture,
                  selectedCategory: _categories[_selectedCategoryIndex],
                  currentPage: _resultsPage,
                  onPageChanged: _changeResultsPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _LiveMatchesView extends StatelessWidget {
  const _LiveMatchesView({required this.selectedCategory});

  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    final liveMatch = MatchData(
      matchNo: 9959,
      team1Name: 'Gujarat Titans',
      team2Name: 'Royal Challengers Bengaluru',
      date: '2026-07-29',
      groundName: 'M. Chinnaswamy Stadium, Bengaluru',
      format: 'T20',
      tournament: 'Indian Premier League T20 2026',
      resultDetail: 'RCB won by 5 wickets (with 4 balls remaining)',
      team1: 988,
      team2: 991,
      status: 'Live',
      season: '2025-26',
      cityName: 'Bengaluru',
      countryName: 'India',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFEB2B2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFE53E3E), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('LIVE BROADCAST MATCHES', style: TextStyle(color: Color(0xFFC53030), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MatchCard(
            match: liveMatch,
            onTap: () {
              // ignore: avoid_print
              print('[DEBUG MatchesScreen] User tapped Live Match #${liveMatch.matchNo}: ${liveMatch.team1Name} vs ${liveMatch.team2Name}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchDetailScreen(matchNo: liveMatch.matchNo, initialMatch: liveMatch),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


class _MatchesListView extends StatefulWidget {
  const _MatchesListView({
    required this.responseFuture,
    required this.selectedCategory,
    required this.currentPage,
    required this.onPageChanged,
  });

  final Future<MatchesResponse> responseFuture;
  final String selectedCategory;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  State<_MatchesListView> createState() => _MatchesListViewState();
}

class _MatchesListViewState extends State<_MatchesListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _MatchesListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MatchesResponse>(
        future: widget.responseFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // ignore: avoid_print
            print('[DEBUG _MatchesListView] Error loading matches: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, color: K.green, size: 48),
                    const SizedBox(height: 12),
                    const Text('Unable to load matches', style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: K.body, fontSize: 12)),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: K.green));
          }

          final response = snapshot.data!;
          var matches = response.matches;
          final pagination = response.pagination;

          if (widget.selectedCategory != 'All') {
            final catLower = widget.selectedCategory.toLowerCase();
            matches = matches.where((m) =>
                m.tournament.toLowerCase().contains(catLower) ||
                m.format.toLowerCase().contains(catLower) ||
                (catLower == 'psl' && m.tournament.toLowerCase().contains('premier league')) ||
                (catLower == 'women' && m.tournament.toLowerCase().contains('women'))
            ).toList();
          }

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                if (matches.isNotEmpty) ...[
                  for (final match in matches)
                    MatchCard(
                      match: match,
                      onTap: () {
                        // ignore: avoid_print
                        print('[DEBUG MatchesScreen] User tapped Match #${match.matchNo}: ${match.team1Name} vs ${match.team2Name}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MatchDetailScreen(matchNo: match.matchNo, initialMatch: match),
                          ),
                        );
                      },
                    ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_cricket, color: Color(0xFFB0BEB3), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No ${widget.selectedCategory} matches on Page ${widget.currentPage}',
                          style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        const Text('Use the pagination bar below to switch pages or select "All".', textAlign: TextAlign.center, style: TextStyle(color: K.body, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                
                // Dynamic Pagination Control Bar
                _buildPaginationBar(context, pagination),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );

  Widget _buildPaginationBar(BuildContext context, PaginationData pagination) {
    final cur = widget.currentPage;
    final total = pagination.totalPages > 0 ? pagination.totalPages : 1;

    final pages = <int>[];
    int start = (cur - 2).clamp(1, total);
    int end = (start + 4).clamp(1, total);
    if (end - start < 4 && start > 1) {
      start = (end - 4).clamp(1, total);
    }
    for (int p = start; p <= end; p++) {
      pages.add(p);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          // First Button
          _pageBtn(
            label: 'First',
            disabled: cur <= 1,
            onTap: () {
              widget.onPageChanged(1);
              _scrollToTop();
            },
          ),
          // Previous Button
          _pageBtn(
            label: 'Previous',
            disabled: cur <= 1,
            onTap: () {
              widget.onPageChanged(cur - 1);
              _scrollToTop();
            },
          ),

          // Numeric Page Buttons (1, 2, 3, 4, 5...)
          for (final p in pages)
            GestureDetector(
              onTap: () {
                widget.onPageChanged(p);
                _scrollToTop();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p == cur ? K.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: p == cur ? null : Border.all(color: const Color(0xFFDCDFDB)),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      color: p == cur ? Colors.white : K.dark,
                      fontSize: 13,
                      fontWeight: p == cur ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Next Button
          _pageBtn(
            label: 'Next',
            disabled: cur >= total,
            onTap: () {
              widget.onPageChanged(cur + 1);
              _scrollToTop();
            },
          ),
          // Last Button
          _pageBtn(
            label: 'Last',
            disabled: cur >= total,
            onTap: () {
              widget.onPageChanged(total);
              _scrollToTop();
            },
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({required String label, required bool disabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF2F4F2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: disabled ? const Color(0xFFE2E4E2) : K.green),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled ? const Color(0xFFA0AAA2) : K.green,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
