import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/tournament_model.dart';
import 'package:kricket_pk/services/tournaments_api.dart';

class TournamentDetailScreen extends StatefulWidget {
  const TournamentDetailScreen({super.key, required this.tournament});
  final TournamentData tournament;

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

                // Winner & Runner Up Cards Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildWinnerCard(
                          title: 'WINNER',
                          teamName: t.winnerName ?? (t.isFinished ? 'Winner' : 'TBD'),
                          isWinner: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildWinnerCard(
                          title: 'RUNNER UP',
                          teamName: t.runnerUpName ?? (t.isFinished ? 'Runner Up' : 'TBD'),
                          isWinner: false,
                        ),
                      ),
                    ],
                  ),
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

        return ListView.builder(
          padding: const EdgeInsets.all(20),
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
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 28 + safeBottom),
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
              'Detailed match schedules will be updated as confirmed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: K.body, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTab(TournamentData t) {
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

  Widget _buildResultTab(TournamentData t) {
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
                  : 'Completed match scorecards and results will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: K.body, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointTableTab(TournamentData t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE0E0E0), width: 1),
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1.2),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF4F7F4)),
            children: [
              Padding(padding: EdgeInsets.all(10), child: Text('Team', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              Padding(padding: EdgeInsets.all(10), child: Text('P', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(10), child: Text('W', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(10), child: Text('L', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(10), child: Text('Pts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center)),
            ],
          ),
          TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(10), child: Text(t.winnerName ?? 'Team 1', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              const Padding(padding: EdgeInsets.all(10), child: Text('10', textAlign: TextAlign.center)),
              const Padding(padding: EdgeInsets.all(10), child: Text('8', textAlign: TextAlign.center)),
              const Padding(padding: EdgeInsets.all(10), child: Text('2', textAlign: TextAlign.center)),
              const Padding(padding: EdgeInsets.all(10), child: Text('16', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: K.green))),
            ],
          ),
          const TableRow(
            children: [
              Padding(padding: EdgeInsets.all(10), child: Text('Runner Up', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Padding(padding: EdgeInsets.all(10), child: Text('10', textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(10), child: Text('6', textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(10), child: Text('4', textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(10), child: Text('12', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(TournamentData t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined, color: K.body, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Tournament Statistics',
              style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Top run scorers, highest individual scores & top wicket-takers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: K.body, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsTab(TournamentData t) {
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
              'Latest tournament news stories and editorial updates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: K.body, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
