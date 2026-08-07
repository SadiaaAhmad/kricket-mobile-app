import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/tournament_model.dart';
import 'package:kricket_pk/models/article_model.dart';
import 'package:kricket_pk/models/match_model.dart';
import 'package:kricket_pk/services/tournaments_api.dart';
import 'package:kricket_pk/services/matches_api.dart';
import 'package:kricket_pk/widgets/match_widgets.dart';
import 'package:kricket_pk/widgets/news_widgets.dart';
import 'package:kricket_pk/screens/match_detail_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  const TournamentDetailScreen({super.key, required this.tournament});
  final TournamentData tournament;

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBattingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'TBD';
    try {
      final dt = DateTime.parse(isoString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final startDateFormatted = _formatDate(t.startDate);
    final endDateFormatted = _formatDate(t.endDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: K.dark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [
          Icon(Icons.share_outlined, size: 20),
          SizedBox(width: 16),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tournament Header Banner (Matching Figma Design)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Logo
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7F4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8E2)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.emoji_events, color: K.green, size: 36),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(
                                color: K.dark,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$startDateFormatted to $endDateFormatted'
                              '${t.season.isNotEmpty ? ', ${t.season}' : ''}'
                              '${t.stage.isNotEmpty ? ', ${t.stage}' : ''}',
                              style: const TextStyle(color: K.body, fontSize: 13, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Winner & Runner Up Cards Section (Fast ~50ms resolution, hides empty cards)
                FutureBuilder<List<String>>(
                  future: Future.wait([
                    TournamentsApi().resolveTeamName(t.winnerName ?? '', t.tournamentId),
                    TournamentsApi().resolveTeamName(t.runnerUpName ?? '', t.tournamentId),
                  ]),
                  builder: (context, snapshot) {
                    String winner = snapshot.data?[0].trim() ?? '';
                    String runnerUp = snapshot.data?[1].trim() ?? '';

                    if (winner == 'null' || winner == '-' || winner == '0' || RegExp(r'^\d+$').hasMatch(winner)) {
                      winner = '';
                    }
                    if (runnerUp == 'null' || runnerUp == '-' || runnerUp == '0' || RegExp(r'^\d+$').hasMatch(runnerUp)) {
                      runnerUp = '';
                    }

                    if (winner.isEmpty && runnerUp.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final cards = <Widget>[];
                    if (winner.isNotEmpty) {
                      cards.add(
                        Expanded(
                          child: _buildWinnerCard(
                            title: 'WINNER',
                            teamName: winner,
                            isWinner: true,
                          ),
                        ),
                      );
                    }
                    if (runnerUp.isNotEmpty) {
                      if (cards.isNotEmpty) cards.add(const SizedBox(width: 12));
                      cards.add(
                        Expanded(
                          child: _buildWinnerCard(
                            title: 'RUNNER UP',
                            teamName: runnerUp,
                            isWinner: false,
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cards,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Sub-Tabs Bar (Aligned directly to left edge)
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: EdgeInsets.zero,
                    labelColor: K.green,
                    unselectedLabelColor: K.body,
                    indicatorColor: K.green,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Teams'),
                      Tab(text: 'Fixture'),
                      Tab(text: 'Live'),
                      Tab(text: 'Result'),
                      Tab(text: 'Point Table'),
                      Tab(text: 'Stats'),
                      Tab(text: 'News'),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTeamsTab(t),
            _buildFixtureTab(t),
            _buildLiveTab(t),
            _buildResultTab(t),
            _buildPointTableTab(t),
            _buildStatsTab(t),
            _buildNewsTab(t),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerCard({required String title, required String teamName, required bool isWinner}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: K.body,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                color: isWinner ? const Color(0xFFDAA520) : const Color(0xFFA0A0A0),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  teamName,
                  style: const TextStyle(
                    color: K.dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  softWrap: true,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsTab(TournamentData t) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: TournamentsApi().getTournamentTeams(t.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: K.green),
            ),
          );
        }

        final teams = snapshot.data ?? [];

        if (teams.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups_outlined, color: K.body, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    'Teams for ${t.name}',
                    style: const TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No team roster data recorded for this tournament.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: K.body, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final safeBottom = MediaQuery.paddingOf(context).bottom;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 44 + safeBottom),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final item = teams[index];
            final teamId = item['TeamId'] as int? ?? 0;
            final teamName = item['TeamName'] as String? ?? 'Team ${index + 1}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEF1EE)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: InkWell(
                  onTap: () => _showTeamSquadBottomSheet(context, teamId, teamName),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F7F4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sports_cricket, color: K.green, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            teamName,
                            style: const TextStyle(
                              color: K.dark,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: K.body, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTeamSquadBottomSheet(BuildContext context, int teamId, String teamName) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              bottom: true,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: K.green, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$teamName Squad',
                            style: const TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: TournamentsApi().getSquadByTeam(teamId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: K.green));
                        }
                        final players = snapshot.data ?? [];
                        if (players.isEmpty) {
                          return const Center(
                            child: Text('No squad player data found for this team.', style: TextStyle(color: K.body)),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 44 + safeBottom),
                          itemCount: players.length,
                          itemBuilder: (context, idx) {
                            final p = players[idx];
                            final name = p['FullName'] as String? ?? 'Player ${idx + 1}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FBF9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFEFF2EF)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFFE2EBE2),
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(color: K.green, fontSize: 11, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      name,
                                      style: const TextStyle(color: K.dark, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFixtureTab(TournamentData t) {
    return FutureBuilder<List<MatchData>>(
      future: MatchesApi().getFixturesByTournament(t.tournamentId, t.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: K.green));
        }

        final tournamentFixtures = snapshot.data ?? [];

        if (tournamentFixtures.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_outlined, color: K.body, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    'Fixtures for ${t.name}',
                    style: const TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No match fixtures currently scheduled for this tournament.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: K.body, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final safeBottom = MediaQuery.paddingOf(context).bottom;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + safeBottom),
          itemCount: tournamentFixtures.length,
          itemBuilder: (context, index) {
            final match = tournamentFixtures[index];
            return MatchCard(
              match: match,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchDetailScreen(matchNo: match.matchNo, initialMatch: match),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLiveTab(TournamentData t) {
    return FutureBuilder<MatchesResponse>(
      future: MatchesApi().getFixtures(limit: 10, page: 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: K.green));
        }

        final liveMatches = (snapshot.data?.matches ?? []).where((m) {
          final mTour = m.tournament.trim().toLowerCase();
          final tName = t.name.trim().toLowerCase();
          final isLiveStatus = m.status.toLowerCase() == 'live' || m.status.toLowerCase() == 'l';
          if (!isLiveStatus) return false;
          if (m.tournamentId > 0 && t.tournamentId > 0 && m.tournamentId == t.tournamentId) {
            return true;
          }
          return mTour.isNotEmpty && (mTour == tName || (tName.length >= 6 && (mTour.contains(tName) || tName.contains(mTour))));
        }).toList();

        if (liveMatches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.isLive ? Icons.sensors : Icons.sensors_off, color: t.isLive ? Colors.red : K.body, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    t.isLive ? 'Ongoing Live Match' : 'No Live Match Currently',
                    style: const TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.isLive
                        ? 'Real-time live scores for ${t.name} are active.'
                        : 'Live scoring updates will appear here during live tournament matches.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: K.body, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final safeBottom = MediaQuery.paddingOf(context).bottom;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + safeBottom),
          itemCount: liveMatches.length,
          itemBuilder: (context, index) {
            final match = liveMatches[index];
            return MatchCard(
              match: match,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchDetailScreen(matchNo: match.matchNo, initialMatch: match),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildResultTab(TournamentData t) {
    return FutureBuilder<List<MatchData>>(
      future: MatchesApi().getResultsByTournament(t.tournamentId, t.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: K.green));
        }

        final tournamentResults = snapshot.data ?? [];

        if (tournamentResults.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.scoreboard_outlined, color: K.body, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    'Match Results for ${t.name}',
                    style: const TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.winnerName != null
                        ? 'Winner: ${t.winnerName}'
                        : 'No completed match results recorded for this tournament.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: K.body, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final safeBottom = MediaQuery.paddingOf(context).bottom;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + safeBottom),
          itemCount: tournamentResults.length,
          itemBuilder: (context, index) {
            final match = tournamentResults[index];
            return MatchCard(
              match: match,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchDetailScreen(matchNo: match.matchNo, initialMatch: match),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPointTableTab(TournamentData t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_chart_outlined, color: K.body, size: 44),
            const SizedBox(height: 12),
            Text(
              'Point Table for ${t.name}',
              style: const TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'No point table standings recorded for this tournament.',
              textAlign: TextAlign.center,
              style: TextStyle(color: K.body, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _getVal(Map<String, dynamic> map, List<String> possibleKeys) {
    for (final key in possibleKeys) {
      if (map.containsKey(key) && map[key] != null) {
        final val = '${map[key]}'.trim();
        if (val.isNotEmpty && val != 'null') return val;
      }
      final lowerKey = key.toLowerCase();
      for (final entry in map.entries) {
        if (entry.key.toLowerCase() == lowerKey && entry.value != null) {
          final val = '${entry.value}'.trim();
          if (val.isNotEmpty && val != 'null') return val;
        }
      }
    }
    return '-';
  }

  Widget _buildStatsTab(TournamentData t) {
    return Column(
      children: [
        // Two buttons for Batting & Bowling Stats
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBattingStats = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isBattingStats ? K.dark : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '🏏 BATTING STATS',
                        style: TextStyle(
                          color: _isBattingStats ? K.lime : K.body,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBattingStats = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isBattingStats ? K.dark : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '⚾ BOWLING STATS',
                        style: TextStyle(
                          color: !_isBattingStats ? K.lime : K.body,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Dynamic Stats Data Display (Vertical Card List with all details)
        Expanded(
          child: _isBattingStats
              ? FutureBuilder<List<Map<String, dynamic>>>(
                  future: TournamentsApi().getBattingStatsByTournament(t.tournamentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: K.green));
                    }
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sports_cricket, color: K.body, size: 44),
                              const SizedBox(height: 12),
                              Text('Batting Stats for ${t.name}', style: const TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              const Text('No batting stat records available for this tournament.', textAlign: TextAlign.center, style: TextStyle(color: K.body, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }
                    final safeBottom = MediaQuery.paddingOf(context).bottom;
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + safeBottom),
                      itemCount: list.length,
                      itemBuilder: (context, idx) {
                        final item = list[idx];
                        final player = _getVal(item, ['PlayerName', 'FullName', 'BatterName', 'Player_Name', 'batter_name', 'name', 'Player']);
                        final playerText = player.isNotEmpty ? player : 'Player ${idx + 1}';
                        final team = _getVal(item, ['TeamName', 'Team_Name', 'team_name', 'Team', 'team']);
                        final matches = _getVal(item, ['Matches', 'M', 'MatchesPlayed', 'matches']);
                        final inns = _getVal(item, ['Innings', 'Inns', 'innings', 'inns', 'I']);
                        final no = _getVal(item, ['NO', 'NotOuts', 'not_outs', 'no']);
                        final runs = _getVal(item, ['Runs', 'TotalRuns', 'runs', 'R', 'total_runs']);
                        final balls = _getVal(item, ['Balls', 'BallsFaced', 'BF', 'balls']);
                        final hs = _getVal(item, ['High score', 'HighScore', 'HighestRuns', 'High_Score', 'HS', 'hs', 'high_score', 'High Run']);
                        final avg = _getVal(item, ['Average', 'Avg', 'average', 'avg']);
                        final sr = _getVal(item, ['StrikeRate', 'Strike Rate', 'SR', 'sr', 'strike_rate']);
                        final fours = _getVal(item, ['4s', '4S', '4', 'Fours', 'fours']);
                        final sixes = _getVal(item, ['6s', '6S', '6', 'Sixes', 'sixes']);
                        final h100 = _getVal(item, ['100s', '100S', '100', 'Hundreds', 'C2', 'hundreds']);
                        final h50 = _getVal(item, ['50s', '50S', '50', 'Fifties', 'C1', 'fifties']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8E2)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: K.dark,
                                    child: Text('${idx + 1}', style: const TextStyle(color: K.lime, fontSize: 12, fontWeight: FontWeight.w800)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(playerText, style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700)),
                                        if (team.isNotEmpty && team != '-') Text(team, style: const TextStyle(color: K.body, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${runs.isEmpty ? '0' : runs} RUNS', style: const TextStyle(color: K.green, fontSize: 14, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1, color: Color(0xFFF0F0F0)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _buildStatPill('M', matches),
                                  _buildStatPill('Inns', inns),
                                  _buildStatPill('NO', no),
                                  _buildStatPill('Balls', balls),
                                  _buildStatPill('HS', hs),
                                  _buildStatPill('Avg', avg),
                                  _buildStatPill('SR', sr),
                                  _buildStatPill('4s', fours),
                                  _buildStatPill('6s', sixes),
                                  _buildStatPill('100s', h100),
                                  _buildStatPill('50s', h50),
                                ].whereType<Widget>().toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                )
              : FutureBuilder<List<Map<String, dynamic>>>(
                  future: TournamentsApi().getBowlingStatsByTournament(t.tournamentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: K.green));
                    }
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sports_baseball_outlined, color: K.body, size: 44),
                              const SizedBox(height: 12),
                              Text('Bowling Stats for ${t.name}', style: const TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              const Text('No bowling stat records available for this tournament.', textAlign: TextAlign.center, style: TextStyle(color: K.body, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }
                    final safeBottom = MediaQuery.paddingOf(context).bottom;
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + safeBottom),
                      itemCount: list.length,
                      itemBuilder: (context, idx) {
                        final item = list[idx];
                        final player = _getVal(item, ['PlayerName', 'FullName', 'BowlerName', 'Player_Name', 'bowler_name', 'name', 'Player']);
                        final playerText = player.isNotEmpty ? player : 'Player ${idx + 1}';
                        final team = _getVal(item, ['TeamName', 'Team_Name', 'team_name', 'Team', 'team']);
                        final matches = _getVal(item, ['Matches', 'M', 'MatchesPlayed', 'matches']);
                        final inns = _getVal(item, ['Innings', 'Inns', 'innings', 'inns', 'I']);
                        final overs = _getVal(item, ['Overs', 'O', 'overs', 'o', 'OversBowled']);
                        final runs = _getVal(item, ['RunsConceded', 'Runs', 'runs_conceded', 'RC', 'R']);
                        final wkts = _getVal(item, ['Wickets', 'Wkts', 'TotalWickets', 'wickets', 'wkts', 'W']);
                        final bbm = _getVal(item, ['BestBowling', 'BBM', 'BBI', 'BestInningBowling', 'best_bowling', 'B']);
                        final avg = _getVal(item, ['Average', 'Avg', 'average', 'avg']);
                        final econ = _getVal(item, ['Economy', 'Econ', 'EconomyRate', 'economy', 'econ', 'E']);
                        final sr = _getVal(item, ['StrikeRate', 'SR', 'sr', 'strike_rate']);
                        final fw = _getVal(item, ['4w', '4W', 'FourWkts', 'four_wickets', '4']);
                        final fiw = _getVal(item, ['5w', '5W', 'FiveWkts', 'five_wickets', '5']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8E2)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: K.dark,
                                    child: Text('${idx + 1}', style: const TextStyle(color: K.lime, fontSize: 12, fontWeight: FontWeight.w800)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(playerText, style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700)),
                                        if (team.isNotEmpty && team != '-') Text(team, style: const TextStyle(color: K.body, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${wkts.isEmpty ? '0' : wkts} WKTS', style: const TextStyle(color: K.green, fontSize: 14, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1, color: Color(0xFFF0F0F0)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _buildStatPill('M', matches),
                                  _buildStatPill('Inns', inns),
                                  _buildStatPill('Overs', overs),
                                  _buildStatPill('Runs', runs),
                                  _buildStatPill('BBM', bbm),
                                  _buildStatPill('Avg', avg),
                                  _buildStatPill('Econ', econ),
                                  _buildStatPill('SR', sr),
                                  _buildStatPill('4w', fw),
                                  _buildStatPill('5w', fiw),
                                ].whereType<Widget>().toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget? _buildStatPill(String label, String value) {
    final cleanVal = value.trim();
    if (cleanVal.isEmpty || cleanVal == '-' || cleanVal == 'null' || cleanVal == '0.00' || cleanVal == '0') {
      return null;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEBF0EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: K.body, fontSize: 11, fontWeight: FontWeight.w600)),
          Text(cleanVal, style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildNewsTab(TournamentData t) {
    return FutureBuilder<List<ArticleData>>(
      future: TournamentsApi().getArticlesByTournament(t.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: K.green));
        }

        final articles = snapshot.data ?? [];

        if (articles.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.article_outlined, color: K.body, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    'News & Articles for ${t.name}',
                    style: const TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No news articles currently published for this tournament.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: K.body, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final safeBottom = MediaQuery.paddingOf(context).bottom;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + safeBottom),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return NewsListCard(article: article, articles: articles);
          },
        );
      },
    );
  }
}
