import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/directory_model.dart';
import 'package:kricket_pk/services/players_api.dart';
import 'package:kricket_pk/screens/district_detail_screen.dart';
import 'package:kricket_pk/screens/team_detail_screen.dart';
import 'package:kricket_pk/screens/club_detail_screen.dart';

class RegionDetailScreen extends StatefulWidget {
  final int regionId;
  final String regionName;

  const RegionDetailScreen({
    super.key,
    required this.regionId,
    required this.regionName,
  });

  @override
  State<RegionDetailScreen> createState() => _RegionDetailScreenState();
}

class _RegionDetailScreenState extends State<RegionDetailScreen> with SingleTickerProviderStateMixin {
  final _playersApi = PlayersApi();
  late final TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic>? _regionDetail;
  List<DirectoryItem> _associations = [];
  List<DirectoryItem> _teams = [];
  List<DirectoryItem> _clubs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRegionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegionData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _playersApi.getRegionDetail(widget.regionId),
        _playersApi.getAssociationsByRegion(widget.regionId),
        _playersApi.getTeamsByRegion(widget.regionId),
        _playersApi.getClubsByRegion(widget.regionId),
      ]);

      if (mounted) {
        setState(() {
          _regionDetail = results[0] as Map<String, dynamic>?;
          _associations = results[1] as List<DirectoryItem>;
          _teams = results[2] as List<DirectoryItem>;
          _clubs = results[3] as List<DirectoryItem>;
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
    final title = _regionDetail?['RegionName'] ?? widget.regionName;
    final shortName = _regionDetail?['ShortName'] ?? '';
    final countryName = _regionDetail?['CountryName'] ?? 'Pakistan';
    final isValid = _regionDetail?['Valid'] == 1;

    final president = '${_regionDetail?['President'] ?? ''}'.trim();
    final secretary = '${_regionDetail?['Secretary'] ?? ''}'.trim();
    final treasurer = '${_regionDetail?['Treasurer'] ?? ''}'.trim();

    final hasOfficials = president.isNotEmpty || secretary.isNotEmpty || (treasurer.isNotEmpty && treasurer != 'null');

    final initialLetter = title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : 'R';

    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        title: const Text(
          'Region Details',
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
                  // Top Hero Card (Matching Figma & Screenshot layout)
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
                        // Left Image / Logo Box
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              shortName.toString().isNotEmpty ? shortName.toString() : initialLetter,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.trim().isNotEmpty ? title.trim() : 'Region #${widget.regionId}',
                                style: const TextStyle(color: K.dark, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${shortName.toString().isNotEmpty ? shortName : 'Region'} | Region',
                                style: const TextStyle(color: K.body, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Overview Grid Container (Matching Screenshot 2-Column Cards Layout!)
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
                        const SizedBox(height: 8),
                        _buildOverviewItem(icon: Icons.account_balance_outlined, text: title.trim()),
                        _buildOverviewItem(icon: Icons.public, text: countryName.toString()),
                        const SizedBox(height: 12),

                        // Row 1: Region Name & Region ID
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'REGION NAME',
                                value: title.trim(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'REGION ID',
                                value: '${widget.regionId}',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 2: Short Name & Status
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'SHORT NAME',
                                value: shortName.toString().isNotEmpty ? shortName.toString() : 'N/A',
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

                        const SizedBox(height: 12),

                        // Row 3: Country Name
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'COUNTRY NAME',
                                value: countryName.toString().isNotEmpty ? countryName.toString() : 'Pakistan',
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox.shrink()),
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
                            'Region Officials',
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
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('DISTRICTS (${_associations.length})'))),
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('TEAMS (${_teams.length})'))),
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('CLUBS (${_clubs.length})'))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sub-Tabs Content
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final index = _tabController.index;
                      if (index == 0) {
                        return _buildAssocList(_associations, 'No district associations found in this region.');
                      } else if (index == 1) {
                        return _buildTeamList(_teams, 'No regional teams found.');
                      } else {
                        return _buildClubList(_clubs, 'No regional clubs found.');
                      }
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: K.dark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: K.dark, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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

  Widget _buildAssocList(List<DirectoryItem> items, String emptyMsg) {
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
              builder: (_) => DistrictDetailScreen(associationId: item.id, associationName: item.title),
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
                const Icon(Icons.account_balance_outlined, color: K.green, size: 20),
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
}
