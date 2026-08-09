import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/directory_model.dart';
import 'package:kricket_pk/services/players_api.dart';
import 'package:kricket_pk/screens/club_detail_screen.dart';
import 'package:kricket_pk/screens/team_detail_screen.dart';
import 'package:kricket_pk/screens/ground_detail_screen.dart';

class CityDetailScreen extends StatefulWidget {
  final int cityId;
  final String cityName;

  const CityDetailScreen({
    super.key,
    required this.cityId,
    required this.cityName,
  });

  @override
  State<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends State<CityDetailScreen> with SingleTickerProviderStateMixin {
  final _playersApi = PlayersApi();
  late final TabController _tabController;

  bool _isLoading = true;
  List<DirectoryItem> _clubs = [];
  List<DirectoryItem> _teams = [];
  List<DirectoryItem> _grounds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCityData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCityData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _playersApi.getClubsByCity(widget.cityId, widget.cityName),
        _playersApi.getTeamsByCity(widget.cityId, widget.cityName),
        _playersApi.getGroundsByCity(widget.cityId, widget.cityName),
      ]);

      if (mounted) {
        setState(() {
          _clubs = results[0];
          _teams = results[1];
          _grounds = results[2];
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
    final initialLetter = widget.cityName.trim().isNotEmpty ? widget.cityName.trim()[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        title: const Text(
          'City Details',
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
                                widget.cityName.trim(),
                                style: const TextStyle(color: K.dark, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'City #${widget.cityId} | Pakistan',
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

                        // Row 1: City Name & ID
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'CITY NAME',
                                value: widget.cityName.trim(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'CITY ID',
                                value: '${widget.cityId}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

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
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('CLUBS (${_clubs.length})'))),
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('TEAMS (${_teams.length})'))),
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('GROUNDS (${_grounds.length})'))),
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
                        return _buildItemList(_clubs, 'No cricket clubs listed for this city.', 'Club');
                      } else if (index == 1) {
                        return _buildItemList(_teams, 'No cricket teams listed for this city.', 'Team');
                      } else {
                        return _buildItemList(_grounds, 'No cricket grounds listed for this city.', 'Ground');
                      }
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildGridItem({required String title, String? value}) {
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
          Text(
            value ?? 'N/A',
            style: const TextStyle(color: K.dark, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(List<DirectoryItem> items, String emptyMsg, String type) {
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
          onTap: () {
            if (type == 'Club') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: item.id, clubName: item.title)));
            } else if (type == 'Team') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDetailScreen(teamId: item.id, teamName: item.title)));
            } else if (type == 'Ground') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => GroundDetailScreen(groundId: item.id, groundName: item.title)));
            }
          },
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
                Icon(
                  type == 'Club' ? Icons.shield_outlined : (type == 'Team' ? Icons.groups_outlined : Icons.stadium_outlined),
                  color: K.green,
                  size: 20,
                ),
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
                const Icon(Icons.arrow_forward_ios, size: 14, color: K.green),
              ],
            ),
          ),
        );
      },
    );
  }
}
