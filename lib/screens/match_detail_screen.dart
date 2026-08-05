import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/match_model.dart';
import 'package:kricket_pk/models/commentary_model.dart';
import 'package:kricket_pk/services/matches_api.dart';
import 'package:kricket_pk/widgets/match_widgets.dart';

class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({
    super.key,
    required this.matchNo,
    this.initialMatch,
  });

  final int matchNo;
  final MatchData? initialMatch;

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late final Future<List<InningsData>> scorecardFuture;
  late final Future<List<CommentaryOverData>> commentaryFuture;
  late TabController _tabController;
  late final bool isMatchLive;

  @override
  void initState() {
    super.initState();
    isMatchLive = widget.initialMatch?.status == 'L' || widget.initialMatch?.status == 'Live';
    _tabController = TabController(length: 3, vsync: this);
    // ignore: avoid_print
    print('[DEBUG MatchDetailScreen] Opened MatchDetailScreen for Match #${widget.matchNo} (Live: $isMatchLive)');
    scorecardFuture = MatchesApi().getScorecard(widget.matchNo);
    if (isMatchLive) {
      commentaryFuture = MatchesApi().getCommentary(widget.matchNo);
    } else {
      commentaryFuture = Future.value([]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: K.bg,
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
            widget.initialMatch != null
                ? '${widget.initialMatch!.team1Name} vs ${widget.initialMatch!.team2Name}'
                : 'Match #${widget.matchNo}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: const [
            Icon(Icons.share_outlined, size: 20),
            SizedBox(width: 16),
          ],
        ),
        body: FutureBuilder<List<InningsData>>(
          future: scorecardFuture,
          builder: (context, snapshot) {
            final inningsList = snapshot.data ?? [];
            final match = widget.initialMatch;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _buildHeroHeader(match, inningsList),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: K.dark,
                      unselectedLabelColor: K.body,
                      indicatorColor: K.lime,
                      indicatorWeight: 3.5,
                      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      tabs: const [
                        Tab(text: 'Summary'),
                        Tab(text: 'Scorecard'),
                        Tab(text: 'Commentary'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(match, inningsList),
                  _ScorecardTabWidget(inningsList: inningsList, match: match),
                  _CommentaryTabWidget(
                    commentaryFuture: commentaryFuture,
                    matchNo: widget.matchNo,
                    isMatchLive: isMatchLive,
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _buildHeroHeader(MatchData? match, List<InningsData> inningsList) {
    final team1Name = (match?.team1Name != null && match!.team1Name.trim().isNotEmpty && match.team1Name != 'Team 1')
        ? match.team1Name
        : (inningsList.isNotEmpty && inningsList[0].battingTeamName.trim().isNotEmpty ? inningsList[0].battingTeamName : 'Team 1');
    final team2Name = (match?.team2Name != null && match!.team2Name.trim().isNotEmpty && match.team2Name != 'Team 2')
        ? match.team2Name
        : (inningsList.length > 1 && inningsList[1].battingTeamName.trim().isNotEmpty ? inningsList[1].battingTeamName : 'Team 2');

    InningsData? team1Innings;
    InningsData? team2Innings;
    for (final inn in inningsList) {
      if (inn.battingTeamName.toLowerCase() == team1Name.toLowerCase()) {
        team1Innings = inn;
      } else if (inn.battingTeamName.toLowerCase() == team2Name.toLowerCase()) {
        team2Innings = inn;
      }
    }
    if (team1Innings == null && inningsList.isNotEmpty) team1Innings = inningsList[0];
    if (team2Innings == null && inningsList.length > 1) team2Innings = inningsList[1];

    final resultDetail = match?.resultDetail;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [K.dark, Color(0xFF002413)],
        ),
      ),
      child: Column(
        children: [
          Text(
            '${(match?.team1Name ?? 'PAK').toUpperCase()} VS ${(match?.team2Name ?? 'AUS').toUpperCase()} — ${match?.format.toUpperCase() ?? '1ST ODI'}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: K.lime, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8),
          ),
          const SizedBox(height: 16),

          // Main Scoreboard Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Team 1
              Expanded(
                child: Column(
                  children: [
                    TeamAvatar(name: team1Name),
                    const SizedBox(height: 8),
                    Text(team1Name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (team1Innings != null) ...[
                      Text('${team1Innings.score}/${team1Innings.wickets}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text('OVERS: ${team1Innings.overs}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                    ] else
                      const Text('Not Available', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              // Team 2
              Expanded(
                child: Column(
                  children: [
                    TeamAvatar(name: team2Name),
                    const SizedBox(height: 8),
                    Text(team2Name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (team2Innings != null) ...[
                      Text('${team2Innings.score}/${team2Innings.wickets}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text('OVERS: ${team2Innings.overs}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                    ] else
                      const Text('Not Available', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                match?.groundName != null && match!.groundName.isNotEmpty ? match.groundName : 'Venue Not Available',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          if (resultDetail != null && resultDetail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              resultDetail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: K.lime, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryTab(MatchData? match, List<InningsData> inningsList) {
    final bool isScheduledFixture = match?.status == 'S' || ((match?.resultDetail == null || match!.resultDetail!.isEmpty) && inningsList.isEmpty && (match?.inningsSummaries == null || match!.inningsSummaries.isEmpty));

    // If scheduled fixture, ONLY show Match Overview!
    if (isScheduledFixture) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECE8)),
                boxShadow: const [BoxShadow(color: Color(0x0A00341C), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MATCH OVERVIEW', style: TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .5)),
                  const SizedBox(height: 12),
                  _infoRow('Tournament', match?.tournament ?? 'N/A'),
                  _infoRow('Match No', '#${widget.matchNo}'),
                  _infoRow('Format', match?.format ?? 'T20'),
                  _infoRow('Season', match?.season ?? '2025-26'),
                  _infoRow('Venue Ground', match?.groundName ?? 'TBA'),
                  _infoRow('Date & Time', match?.date ?? 'TBA'),
                  if (match?.cityName != null) _infoRow('City', match!.cityName!),
                  if (match?.countryName != null) _infoRow('Country', match!.countryName!),
                  _infoRow('Official Status', 'Official PCB / ICC Fixture'),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      );
    }

    // Otherwise, construct innings display list for completed/live matches
    final List<InningsData> displayInnings;
    if (inningsList.isNotEmpty) {
      displayInnings = inningsList;
    } else if (match != null && match.inningsSummaries.isNotEmpty) {
      displayInnings = [
        for (final summ in match.inningsSummaries)
          InningsData(
            matchNo: match.matchNo,
            innings: summ.innings,
            score: summ.score,
            overs: summ.overs,
            wickets: summ.wickets,
            battingTeamName: summ.battingTeamName,
            bowlingTeamName: summ.bowlingTeamName,
            battingDetail: const [],
            bowlingDetail: const [],
          )
      ];
    } else {
      displayInnings = const [];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Result Detail Banner
          if (match?.resultDetail != null && match!.resultDetail!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F3EC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC2E4D2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFF0B7337), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MATCH RESULT', style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5)),
                        const SizedBox(height: 2),
                        Text(match.resultDetail!, style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Innings Summary Cards with Top Batters & Bowlers
          if (displayInnings.isNotEmpty) ...[
            const Text('INNINGS BREAKDOWN', style: TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .5)),
            const SizedBox(height: 10),
            for (final inn in displayInnings) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8ECE8)),
                  boxShadow: const [BoxShadow(color: Color(0x0A00341C), blurRadius: 6)],
                ),
                child: Column(
                  children: [
                    // Green Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B7337),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: Row(
                        children: [
                          TeamAvatar(name: inn.battingTeamName, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${inn.battingTeamName} (Innings ${inn.innings})',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${inn.score}/${inn.wickets}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            ' (${inn.overs} ov)',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),

                    // Top Performers Row (Batters on Left, Bowlers on Right)
                    if (inn.battingDetail.isNotEmpty || inn.bowlingDetail.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top 3 Batters
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final b in (List<BattingDetail>.from(inn.battingDetail)..sort((a, b) => b.runs.compareTo(a.runs))).take(3))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              b.batsmanName,
                                              style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${b.runs} (${b.ballsFaced})',
                                            style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Top 3 Bowlers
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final bw in (List<BowlingDetail>.from(inn.bowlingDetail)..sort((a, b) => b.wickets != a.wickets ? b.wickets.compareTo(a.wickets) : a.runs.compareTo(b.runs))).take(3))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              bw.bowlerName,
                                              style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${bw.wickets}-${bw.runs} (${bw.overs})',
                                            style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('vs ${inn.bowlingTeamName}', style: const TextStyle(color: K.body, fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('Run Rate: ${_calcRR(inn.score, double.tryParse(inn.overs) ?? 0.0)}', style: const TextStyle(color: K.body, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // 3. Player of the Match Card (if in API)
          if (match?.manOfMatchName != null && match!.manOfMatchName!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECE8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFB300), size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PLAYER OF THE MATCH', style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5)),
                      const SizedBox(height: 2),
                      Text(match.manOfMatchName!, style: const TextStyle(color: K.ink, fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Match Information Card from API
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECE8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MATCH OVERVIEW', style: TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .5)),
                const SizedBox(height: 12),
                _infoRow('Tournament', match?.tournament ?? 'N/A'),
                _infoRow('Match No', '#${widget.matchNo}'),
                _infoRow('Format', match?.format ?? 'T20'),
                _infoRow('Season', match?.season ?? '2025-26'),
                _infoRow('Venue Ground', match?.groundName ?? 'TBA'),
                _infoRow('Date & Time', match?.date ?? 'TBA'),
                if (match?.cityName != null) _infoRow('City', match!.cityName!),
                if (match?.countryName != null) _infoRow('Country', match!.countryName!),
                _infoRow('Official Status', 'Official PCB / ICC Match'),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  String _calcRR(int score, double overs) {
    if (overs <= 0) return '0.0';
    return (score / overs).toStringAsFixed(2);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: K.body, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: K.ink, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ScorecardTabWidget extends StatefulWidget {
  const _ScorecardTabWidget({required this.inningsList, required this.match});
  final List<InningsData> inningsList;
  final MatchData? match;

  @override
  State<_ScorecardTabWidget> createState() => _ScorecardTabWidgetState();
}

class _ScorecardTabWidgetState extends State<_ScorecardTabWidget> {
  int _selectedInningsIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isScheduledFixture = widget.match?.status == 'S' || ((widget.match?.resultDetail == null || widget.match!.resultDetail!.isEmpty) && widget.inningsList.isEmpty && (widget.match?.inningsSummaries == null || widget.match!.inningsSummaries.isEmpty));

    if (isScheduledFixture) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_cricket_outlined, color: Color(0xFFB0BEB3), size: 48),
              const SizedBox(height: 12),
              const Text(
                'No Scorecard Available Yet',
                style: TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Scorecard details will be updated once the match begins.',
                textAlign: TextAlign.center,
                style: TextStyle(color: K.body, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final List<InningsData> displayList;
    if (widget.inningsList.isNotEmpty) {
      displayList = widget.inningsList;
    } else if (widget.match != null && widget.match!.inningsSummaries.isNotEmpty) {
      displayList = [
        for (final summ in widget.match!.inningsSummaries)
          InningsData(
            matchNo: widget.match!.matchNo,
            innings: summ.innings,
            score: summ.score,
            overs: summ.overs,
            wickets: summ.wickets,
            battingTeamName: summ.battingTeamName,
            bowlingTeamName: summ.bowlingTeamName,
            battingDetail: const [],
            bowlingDetail: const [],
          )
      ];
    } else {
      displayList = const [];
    }

    if (displayList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assessment_outlined, color: K.body, size: 44),
              SizedBox(height: 12),
              Text(
                'Data Not Available',
                style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Innings scorecard details are not available for this match.',
                textAlign: TextAlign.center,
                style: TextStyle(color: K.body, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final safeIndex = _selectedInningsIndex.clamp(0, displayList.length - 1);
    final activeInnings = displayList[safeIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Innings Selector Pills Row (1st innings, 2nd innings...)
          if (displayList.length > 1) ...[
            Row(
              children: [
                for (int i = 0; i < displayList.length; i++) ...[
                  GestureDetector(
                    onTap: () => setState(() => _selectedInningsIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                      decoration: BoxDecoration(
                        color: i == safeIndex ? const Color(0xFF2C2C2C) : const Color(0xFFF2F4F2),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: i == safeIndex
                            ? const [BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2))]
                            : null,
                      ),
                      child: Text(
                        '${i == 0 ? '1st' : i == 1 ? '2nd' : '${i + 1}th'} innings',
                        style: TextStyle(
                          color: i == safeIndex ? Colors.white : K.dark,
                          fontSize: 13,
                          fontWeight: i == safeIndex ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Selected Innings Scorecard
          InningsCard(innings: activeInnings),
        ],
      ),
    );
  }
}

class _CommentaryTabWidget extends StatefulWidget {
  const _CommentaryTabWidget({
    required this.commentaryFuture,
    required this.matchNo,
    this.isMatchLive = true,
  });

  final Future<List<CommentaryOverData>> commentaryFuture;
  final int matchNo;
  final bool isMatchLive;

  @override
  State<_CommentaryTabWidget> createState() => _CommentaryTabWidgetState();
}

class _CommentaryTabWidgetState extends State<_CommentaryTabWidget> {
  int _selectedInnings = 1;
  final ScrollController _scrollController = ScrollController();
  int _visibleOversCount = 6; // Initial batch of 6 overs
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      _loadNextOversBatch();
    }
  }

  void _loadNextOversBatch() {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    // Load next batch of 6 overs on scroll
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _visibleOversCount += 6;
          _isLoadingMore = false;
        });
      }
    });
  }

  Future<void> _handleLiveRefresh() async {
    setState(() {
      _visibleOversCount = 6;
    });
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMatchLive) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 64),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.subtitles_off_outlined, color: Color(0xFFB0BEB3), size: 52),
              SizedBox(height: 14),
              Text(
                'No commentary available for this match',
                textAlign: TextAlign.center,
                style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Live ball-by-ball commentary is only available during live ongoing matches.',
                textAlign: TextAlign.center,
                style: TextStyle(color: K.body, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<CommentaryOverData>>(
      future: widget.commentaryFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: K.green));
        }

        final allOvers = snapshot.data!;
        if (allOvers.isEmpty) {
          return RefreshIndicator(
            color: K.green,
            onRefresh: _handleLiveRefresh,
            child: const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 64),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.subtitles_off_outlined, color: Color(0xFFB0BEB3), size: 48),
                    SizedBox(height: 14),
                    Text(
                      'No commentary available for this match',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Live ball-by-ball commentary is only available during live ongoing matches.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: K.body, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final innings1Overs = allOvers.where((o) => o.innings == 1).toList()..sort((a, b) => a.over.compareTo(b.over));
        final innings2Overs = allOvers.where((o) => o.innings == 2).toList()..sort((a, b) => a.over.compareTo(b.over));

        final allCurrentOvers = _selectedInnings == 1
            ? (innings1Overs.isNotEmpty ? innings1Overs : allOvers)
            : (innings2Overs.isNotEmpty ? innings2Overs : allOvers);

        // Paginated overs subset loaded progressively on scroll
        final displayedOvers = allCurrentOvers.take(_visibleOversCount).toList();
        final hasMoreOvers = _visibleOversCount < allCurrentOvers.length;

        return RefreshIndicator(
          color: K.green,
          onRefresh: _handleLiveRefresh,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Innings Selector Dropdown & Live Indicator Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC6F6D5)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.circle, size: 8, color: Color(0xFFE53E3E)),
                          SizedBox(width: 6),
                          Text(
                            'LIVE AUTO-SYNC',
                            style: TextStyle(color: K.green, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),

                    // Innings Selector Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: K.green, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A00341C),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedInnings,
                          isDense: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down, color: K.green),
                          items: [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                innings1Overs.isNotEmpty ? 'GT Innings (${innings1Overs.last.score}/${innings1Overs.last.wicket})' : '1st Innings',
                                style: const TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (innings2Overs.isNotEmpty)
                              DropdownMenuItem(
                                value: 2,
                                child: Text(
                                  'RCB Innings (${innings2Overs.last.score}/${innings2Overs.last.wicket})',
                                  style: const TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedInnings = val;
                                _visibleOversCount = 6; // Reset pagination for selected innings
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Overs List (Loaded on scroll)
                for (final overData in displayedOvers)
                  _buildOverWebStyleCard(overData),

                // Loading Indicator at bottom when scrolling to load next overs
                if (hasMoreOvers || _isLoadingMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: K.green),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Loading next overs...',
                            style: TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverWebStyleCard(CommentaryOverData overData) {
    final shortTeamName = overData.innings == 1 ? 'GT' : 'RCB';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A00341C),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bowler Header Bar (Kricket Green Theme)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.circle, color: K.green, size: 12),
                const SizedBox(width: 8),
                Text(
                  overData.bowlerName.isNotEmpty ? overData.bowlerName : 'Bowler',
                  style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEDF2F7)),

          // Ball Rows List (1 to 6)
          for (final ball in overData.balls)
            _buildBallWebStyleRow(ball),

          // END OF OVER Summary Box (Light Green App Tint)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FFF4),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
              border: Border.all(color: const Color(0xFFC6F6D5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: END OF OVER & Distinct Green Score Badge (Score never hidden/truncated)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'END OF OVER ${overData.over}',
                      style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    // Distinct Green Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: K.green, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F00341C),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$shortTeamName: ${overData.score}/${overData.wicket}',
                        style: const TextStyle(
                          color: K.dark, // Distinct bold dark green score!
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${overData.runsInOver} RUNS',
                      style: const TextStyle(color: Color(0xFF9B2C2C), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'CRR: ${(overData.score / (overData.over > 0 ? overData.over : 1)).toStringAsFixed(2)}',
                      style: const TextStyle(color: K.body, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${overData.strikerName}  ${overData.strikerRuns} (${overData.strikerBalls}b)',
                            style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (overData.nonStrikerName.isNotEmpty)
                            Text(
                              '${overData.nonStrikerName}  ${overData.nonStrikerRuns} (${overData.nonStrikerBalls}b)',
                              style: const TextStyle(color: K.body, fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${overData.bowlerName}  ${overData.bowlerOver}-0-${overData.bowlerRuns}-${overData.bowlerWickets}',
                      style: const TextStyle(color: K.green, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBallWebStyleRow(CommentaryBallData ball) {
    String actionDesc;
    if (ball.isWicket) {
      actionDesc = '${ball.bowlerName} to ${ball.batsmanName}, OUT! ${ball.outDetail ?? ""}';
    } else if (ball.runs == 6) {
      actionDesc = '${ball.bowlerName} to ${ball.batsmanName}, SIX runs';
    } else if (ball.runs == 4) {
      actionDesc = '${ball.bowlerName} to ${ball.batsmanName}, FOUR runs';
    } else if (ball.wide > 0) {
      actionDesc = '${ball.bowlerName} to ${ball.batsmanName}, 1 wide';
    } else if (ball.legByes > 0) {
      actionDesc = '${ball.bowlerName} to ${ball.batsmanName}, ${ball.legByes} leg bye';
    } else if (ball.runs == 0) {
      actionDesc = '${ball.bowlerName} to ${ball.batsmanName}, no run';
    } else {
      actionDesc = '${ball.bowlerName} to ${ball.batsmanName}, ${ball.runs} run${ball.runs == 1 ? "" : "s"}';
    }

    // Score badge colors following App Green Palette (NO BLUE!)
    Color circleBg = K.green;
    String circleText = '${ball.runs}';

    if (ball.isWicket) {
      circleBg = const Color(0xFFE53E3E); // Standard Red Wicket Badge
      circleText = 'W';
    } else if (ball.runs == 6) {
      circleBg = K.green; // Kricket Primary Green
    } else if (ball.runs == 4) {
      circleBg = const Color(0xFF38A169); // Secondary Green
    } else if (ball.runs == 0) {
      circleBg = const Color(0xFF718096); // Muted Slate
    } else if (ball.legByes > 0) {
      circleBg = const Color(0xFF805AD5);
      circleText = '${ball.legByes}Lb';
    } else if (ball.wide > 0) {
      circleBg = const Color(0xFF805AD5);
      circleText = 'Wd';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF7FAFC))),
      ),
      child: Row(
        children: [
          // Light green box with ball number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FFF4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFC6F6D5)),
            ),
            child: Center(
              child: Text(
                '${ball.ball}',
                style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Batter name & commentary line
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_cricket, size: 14, color: K.body),
                    const SizedBox(width: 4),
                    Text(
                      ball.batsmanName,
                      style: const TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  actionDesc,
                  style: const TextStyle(color: K.body, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Circular score badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                circleText,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
