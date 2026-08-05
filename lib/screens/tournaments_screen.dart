import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/tournament_model.dart';
import 'package:kricket_pk/services/tournaments_api.dart';
import 'package:kricket_pk/screens/tournament_detail_screen.dart';
import 'package:kricket_pk/data/real_tournaments.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  late Future<TournamentPaginatedResult> _tournamentsFuture;
  int _currentPage = 1;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    _tournamentsFuture = TournamentsApi().getTournaments(
      page: _currentPage,
      perPage: 10,
      query: _searchQuery,
      category: _selectedCategory,
    );
  }

  void _goToPage(int page, int totalPages) {
    final target = page.clamp(1, totalPages);
    if (target != _currentPage) {
      setState(() {
        _currentPage = target;
        _loadTournaments();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: K.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 12 + safeBottom + 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Hero Card (Matching Figma Redesign)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _buildFeaturedHeroCard(context),
            ),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _currentPage = 1;
                      _loadTournaments();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search tournaments',
                    hintStyle: const TextStyle(color: K.body, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: K.body, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: K.body),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _currentPage = 1;
                                _loadTournaments();
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Domestic'),
                  _buildFilterChip('International'),
                  _buildFilterChip('Leagues'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tournaments List & Pagination FutureBuilder
            FutureBuilder<TournamentPaginatedResult>(
              future: _tournamentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator(color: K.green)),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('Error loading tournaments: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  );
                }

                final result = snapshot.data!;
                final tournaments = result.tournaments;

                if (tournaments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No tournaments found matching your search.',
                        style: TextStyle(color: K.body, fontSize: 14),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        'All Tournaments',
                        style: TextStyle(color: K.dark, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),

                    // 10 Tournaments Per Page
                    for (final t in tournaments)
                      _buildTournamentCard(context, t),

                    const SizedBox(height: 20),

                    // Pagination Control Bar (Matching User Web Screenshot)
                    _buildPaginationBar(result),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedHeroCard(BuildContext context) {
    final liveTournament = getRealTournaments().firstWhere(
      (t) => t.isLive,
      orElse: () => getRealTournaments().first,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003820), Color(0xFF001C10)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x2B004D2C), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.emoji_events,
              size: 160,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (liveTournament.isLive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC3545),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '• LIVE NOW',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: K.lime,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(color: K.limeText, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        liveTournament.format.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  liveTournament.name,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  '${liveTournament.format} • ${liveTournament.stage}${liveTournament.season.isNotEmpty ? ' • Season ${liveTournament.season}' : ''}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TournamentDetailScreen(tournament: liveTournament),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: K.lime,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(color: K.limeText, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 14, color: K.limeText),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String title) {
    final active = _selectedCategory == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
          _currentPage = 1;
          _loadTournaments();
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

  Widget _buildTournamentCard(BuildContext context, TournamentData t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEBEB)),
          boxShadow: const [
            BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TournamentDetailScreen(tournament: t),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo Container
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8E2)),
                  ),
                  child: const Center(
                    child: Icon(Icons.emoji_events_outlined, color: K.green, size: 28),
                  ),
                ),
                const SizedBox(width: 14),

                // Main Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: K.dark,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (t.isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC3545),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '• LIVE',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            )
                          else if (t.isFinished)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9ECEF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FINISHED',
                                style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'UPCOMING',
                                style: TextStyle(color: K.green, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${t.format} • ${t.stage} ${t.season.isNotEmpty ? '• ${t.season}' : ''}',
                        style: const TextStyle(color: K.body, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      if (t.winnerName != null && t.winnerName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.emoji_events, size: 13, color: Color(0xFFDAA520)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Winner: ${t.winnerName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: K.green, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar(TournamentPaginatedResult result) {
    final cur = result.currentPage;
    final total = result.totalPages > 0 ? result.totalPages : 1;
    final totalItems = result.totalItems;

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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECE8)),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: First, Previous, 1, 2, 3, 4, 5
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _pageBtn(
                        label: 'First',
                        disabled: cur <= 1,
                        onTap: () => _goToPage(1, total),
                      ),
                      const SizedBox(width: 5),
                      _pageBtn(
                        label: 'Previous',
                        disabled: cur <= 1,
                        onTap: () => _goToPage(cur - 1, total),
                      ),
                      const SizedBox(width: 5),
                      for (final p in pages) ...[
                        GestureDetector(
                          onTap: () => _goToPage(p, total),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: p == cur ? const Color(0xFF004D2C) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: p == cur ? null : Border.all(color: const Color(0xFFDCDFDB)),
                            ),
                            child: Center(
                              child: Text(
                                '$p',
                                style: TextStyle(
                                  color: p == cur ? Colors.white : const Color(0xFF004D2C),
                                  fontSize: 13,
                                  fontWeight: p == cur ? FontWeight.w800 : FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 2: Next, Last
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _pageBtn(
                        label: 'Next',
                        disabled: cur >= total,
                        onTap: () => _goToPage(cur + 1, total),
                      ),
                      const SizedBox(width: 6),
                      _pageBtn(
                        label: 'Last',
                        disabled: cur >= total,
                        onTap: () => _goToPage(total, total),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Page $cur of $total ($totalItems total tournaments)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: K.body,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({required String label, required bool disabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF2F4F2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled ? const Color(0xFFE2E4E2) : const Color(0xFF004D2C),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled ? const Color(0xFFA0AAA2) : const Color(0xFF004D2C),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
