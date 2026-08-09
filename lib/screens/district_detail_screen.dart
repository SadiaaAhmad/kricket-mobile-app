import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/directory_model.dart';
import 'package:kricket_pk/services/players_api.dart';
import 'package:kricket_pk/screens/club_detail_screen.dart';
import 'package:kricket_pk/screens/team_detail_screen.dart';
import 'package:kricket_pk/screens/region_detail_screen.dart';

class DistrictDetailScreen extends StatefulWidget {
  final int associationId;
  final String associationName;
  final int initialTabIndex;

  const DistrictDetailScreen({
    super.key,
    required this.associationId,
    required this.associationName,
    this.initialTabIndex = 0,
  });

  @override
  State<DistrictDetailScreen> createState() => _DistrictDetailScreenState();
}

class _DistrictDetailScreenState extends State<DistrictDetailScreen> with SingleTickerProviderStateMixin {
  final _playersApi = PlayersApi();
  late final TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic>? _detail;
  List<DirectoryItem> _clubs = [];
  List<DirectoryItem> _teams = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _fetchDistrictData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDistrictData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _playersApi.getAssociationDetail(widget.associationId),
        _playersApi.getClubsByAssociation(widget.associationId),
        _playersApi.getTeamsByAssociation(widget.associationId),
      ]);

      if (mounted) {
        setState(() {
          _detail = results[0] as Map<String, dynamic>?;
          _clubs = results[1] as List<DirectoryItem>;
          _teams = results[2] as List<DirectoryItem>;
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
    final title = _detail?['AssociationName'] ?? widget.associationName;
    final president = '${_detail?['President'] ?? ''}'.trim();
    final secretary = '${_detail?['Secretary'] ?? ''}'.trim();
    final treasurer = '${_detail?['Treasurer'] ?? ''}'.trim();
    final region = _detail?['RegionName'] ?? 'N/A';
    final regionId = _detail?['RegionId'] ?? 0;
    final isValid = _detail?['Valid'] == 1;

    final hasOfficials = president.isNotEmpty || secretary.isNotEmpty || (treasurer.isNotEmpty && treasurer != 'null');
    final initialLetter = title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        title: const Text(
          'District Details',
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
                              InkWell(
                                onTap: regionId > 0
                                    ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RegionDetailScreen(
                                              regionId: regionId,
                                              regionName: region.toString(),
                                            ),
                                          ),
                                        )
                                    : null,
                                child: Text(
                                  'Region: ${region.toString().trim()}',
                                  style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
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

                        // Row 1: District Name & District ID
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'DISTRICT NAME',
                                value: title.trim(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'DISTRICT ID',
                                value: '${widget.associationId}',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 2: Region Name & Status
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'REGION NAME',
                                child: InkWell(
                                  onTap: regionId > 0
                                      ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => RegionDetailScreen(
                                                regionId: regionId,
                                                regionName: region.toString(),
                                              ),
                                            ),
                                          )
                                      : null,
                                  child: Text(
                                    region.toString().trim().isNotEmpty ? region.toString().trim() : 'N/A',
                                    style: const TextStyle(color: K.green, fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'STATUS',
                                value: isValid ? 'Active' : 'Inactive',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Officials Card (ONLY shown if non-empty official data exists in API!)
                  if (hasOfficials) ...[
                    const SizedBox(height: 16),
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
                            'District Officials',
                            style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          if (president.isNotEmpty) _buildInfoRow('President', president),
                          if (secretary.isNotEmpty) _buildInfoRow('Secretary', secretary),
                          if (treasurer.isNotEmpty && treasurer != 'null') _buildInfoRow('Treasurer', treasurer),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Sub-Tabs Header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: K.green,
                      labelColor: K.green,
                      unselectedLabelColor: K.body,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      tabs: [
                        Tab(text: 'CLUBS (${_clubs.length})'),
                        Tab(text: 'TEAMS (${_teams.length})'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tab Bar View Content
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final index = _tabController.index;
                      return index == 0
                          ? _buildClubList(_clubs, 'No clubs found for this district.')
                          : _buildTeamList(_teams, 'No teams found for this district.');
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

  Widget _buildInfoRow(String label, String val) {
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
              val,
              style: const TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubList(List<DirectoryItem> items, String emptyMsg) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Text(emptyMsg, style: const TextStyle(color: K.body, fontSize: 13)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClubDetailScreen(clubId: item.id, clubName: item.title),
            ),
          ),
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
                const Icon(Icons.shield_outlined, color: K.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(color: K.dark, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      if (item.subtitle.isNotEmpty)
                        Text(
                          item.subtitle,
                          style: const TextStyle(color: K.body, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: K.body),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamList(List<DirectoryItem> items, String emptyMsg) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Text(emptyMsg, style: const TextStyle(color: K.body, fontSize: 13)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamDetailScreen(teamId: item.id, teamName: item.title),
            ),
          ),
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
                const Icon(Icons.groups_outlined, color: K.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(color: K.dark, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      if (item.subtitle.isNotEmpty)
                        Text(
                          item.subtitle,
                          style: const TextStyle(color: K.body, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: K.body),
              ],
            ),
          ),
        );
      },
    );
  }
}
