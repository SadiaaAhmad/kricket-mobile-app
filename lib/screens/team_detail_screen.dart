import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/services/players_api.dart';
import 'package:kricket_pk/screens/player_detail_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  final String teamName;

  const TeamDetailScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final _playersApi = PlayersApi();
  bool _isLoading = true;
  Map<String, dynamic>? _teamDetail;
  List<Map<String, dynamic>> _squad = [];

  @override
  void initState() {
    super.initState();
    _fetchTeamData();
  }

  Future<void> _fetchTeamData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _playersApi.getTeamDetail(widget.teamId),
        _playersApi.getSquadByTeam(widget.teamId),
      ]);

      if (mounted) {
        setState(() {
          _teamDetail = results[0] as Map<String, dynamic>?;
          _squad = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final title = _teamDetail?['TeamName'] ?? widget.teamName;
    final level = _teamDetail?['Level'] ?? 'N/A';
    final format = _teamDetail?['Format'] ?? 'N/A';
    final season = _teamDetail?['Season'] ?? 'N/A';
    final coach = _teamDetail?['Coach'] ?? 'N/A';
    final manager = _teamDetail?['Manager'] ?? 'N/A';

    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        title: Text(
          title.trim().isNotEmpty ? title.trim() : 'Team #${widget.teamId}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 48 + safeBottom + 64),
        child: Column(
          children: [
            // Top Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: K.dark,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F7F3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : 'T',
                        style: const TextStyle(color: K.green, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.trim().isNotEmpty ? title.trim() : 'Team #${widget.teamId}',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$level • $format ($season)',
                          style: const TextStyle(color: K.lime, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Team Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team Information',
                      style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildRow('Level', level),
                    _buildRow('Format', format),
                    _buildRow('Season', season),
                    _buildRow('Coach', coach),
                    _buildRow('Manager', manager),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Squad Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Team Squad',
                    style: TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: K.green.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_squad.length}',
                      style: const TextStyle(color: K.green, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Squad List Content
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: K.green)),
              )
            else if (_squad.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('No squad players found for this team.', style: TextStyle(color: K.body, fontSize: 13)),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _squad.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _squad[index];
                    final pName = '${item['FullName'] ?? item['PlayerName'] ?? 'Player'}'.trim();
                    final pId = item['PlayerId'] ?? 0;

                    return InkWell(
                      onTap: pId > 0
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayerDetailScreen(playerId: pId),
                                ),
                              )
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: K.green.withValues(alpha: .15),
                              child: Text(
                                pName.isNotEmpty ? pName[0].toUpperCase() : 'P',
                                style: const TextStyle(color: K.green, fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pName,
                                style: const TextStyle(color: K.dark, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: K.body),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: K.body, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              val.trim().isNotEmpty && val != 'null' ? val.trim() : 'N/A',
              style: const TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
