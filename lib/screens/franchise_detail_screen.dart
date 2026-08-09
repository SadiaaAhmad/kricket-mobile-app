import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/directory_model.dart';
import 'package:kricket_pk/services/players_api.dart';
import 'package:kricket_pk/screens/team_detail_screen.dart';

class FranchiseDetailScreen extends StatefulWidget {
  final int franchiseId;
  final String franchiseName;

  const FranchiseDetailScreen({
    super.key,
    required this.franchiseId,
    required this.franchiseName,
  });

  @override
  State<FranchiseDetailScreen> createState() => _FranchiseDetailScreenState();
}

class _FranchiseDetailScreenState extends State<FranchiseDetailScreen> {
  final _playersApi = PlayersApi();
  bool _isLoading = true;
  Map<String, dynamic>? _franchiseDetail;
  List<DirectoryItem> _teams = [];

  @override
  void initState() {
    super.initState();
    _fetchFranchiseData();
  }

  Future<void> _fetchFranchiseData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _playersApi.getFranchiseDetail(widget.franchiseId),
        _playersApi.getTeamsByFranchise(widget.franchiseId),
      ]);

      if (mounted) {
        setState(() {
          _franchiseDetail = results[0] as Map<String, dynamic>?;
          _teams = results[1] as List<DirectoryItem>;
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
    final title = _franchiseDetail?['FranchiseName'] ?? widget.franchiseName;
    final countryCode = _franchiseDetail?['CountryCode'] ?? 0;
    final leagueText = countryCode == 92 ? 'PSL Franchise (Pakistan)' : (countryCode == 91 ? 'IPL Franchise (India)' : 'Cricket Franchise');
    final initialLetter = title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : 'F';

    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        title: const Text(
          'Franchise Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: K.green))
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 48 + safeBottom + 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Hero Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F7F3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Text(
                              initialLetter,
                              style: const TextStyle(color: K.green, fontSize: 38, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.trim(),
                                style: const TextStyle(color: K.dark, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$leagueText | Franchise #${widget.franchiseId}',
                                style: const TextStyle(color: K.body, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Overview Grid Container
                  Container(
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
                          'Overview',
                          style: TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.3),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Row 1: Franchise Name & ID
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'FRANCHISE NAME',
                                value: title.trim(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'FRANCHISE ID',
                                value: '${widget.franchiseId}',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 2: League & Status
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'LEAGUE / BOARD',
                                value: leagueText,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'STATUS',
                                value: 'Active',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Associated Teams Header
                  Row(
                    children: [
                      const Icon(Icons.sports_cricket, color: K.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Associated Teams (${_teams.length})',
                        style: const TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Associated Teams List
                  if (_teams.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'No franchise teams listed for this franchise.',
                          style: TextStyle(color: K.body, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _teams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final team = _teams[index];
                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeamDetailScreen(teamId: team.id, teamName: team.title),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0x1A004D2C),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.sports_cricket_outlined, color: K.green, size: 22),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        team.title,
                                        style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                      if (team.subtitle.isNotEmpty)
                                        Text(
                                          team.subtitle,
                                          style: const TextStyle(color: K.body, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: K.green),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildGridItem({required String title, String? value, Widget? child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .5),
          ),
          const SizedBox(height: 4),
          child ??
              Text(
                value ?? 'N/A',
                style: const TextStyle(color: K.dark, fontSize: 14, fontWeight: FontWeight.w700),
              ),
        ],
      ),
    );
  }
}
