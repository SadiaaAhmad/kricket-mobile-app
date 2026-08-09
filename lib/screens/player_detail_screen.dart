import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/player_model.dart';
import 'package:kricket_pk/services/players_api.dart';
import 'package:kricket_pk/widgets/net_image.dart';

class PlayerDetailScreen extends StatefulWidget {
  final int playerId;
  final PlayerData? initialData;

  const PlayerDetailScreen({
    super.key,
    required this.playerId,
    this.initialData,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> with SingleTickerProviderStateMixin {
  final _playersApi = PlayersApi();
  late final TabController _tabController;

  bool _isLoading = true;
  PlayerData? _player;
  List<Map<String, dynamic>> _battingStats = [];
  List<Map<String, dynamic>> _bowlingStats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _player = widget.initialData;
    _fetchFullPlayerDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFullPlayerDetails() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _playersApi.getPlayerProfile(widget.playerId),
        _playersApi.getPlayerBatting(widget.playerId),
        _playersApi.getPlayerBowling(widget.playerId),
      ]);

      final profile = results[0] as PlayerData?;
      final batting = results[1] as List<Map<String, dynamic>>;
      final bowling = results[2] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          if (profile != null) _player = profile;
          _battingStats = batting;
          _bowlingStats = bowling;
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
    final player = _player ?? PlayerData(playerId: widget.playerId, fullName: 'Player #${widget.playerId}');
    final role = player.derivedRole;

    Color badgeColor = K.green;
    if (role.toLowerCase().contains('bowl')) badgeColor = Colors.red.shade700;
    if (role.toLowerCase().contains('all')) badgeColor = Colors.amber.shade800;
    if (role.toLowerCase().contains('keeper')) badgeColor = Colors.blue.shade700;

    final initialLetter = player.fullName.isNotEmpty ? player.fullName[0].toUpperCase() : 'P';

    String playerLocation = player.location;
    if (playerLocation.isEmpty && player.city.isNotEmpty) playerLocation = player.city;
    if (playerLocation.isEmpty && player.country.isNotEmpty) playerLocation = player.country;

    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        title: Text(
          player.fullName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 48 + safeBottom + 64),
        child: Column(
          children: [
            // Top Hero Profile Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                color: K.dark,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: player.avatarUrl.isNotEmpty
                        ? () => showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.black,
                                insetPadding: const EdgeInsets.all(16),
                                child: Stack(
                                  children: [
                                    InteractiveViewer(
                                      child: Center(
                                        child: NetImage(
                                          player.avatarUrl,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                        : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: K.green.withValues(alpha: .4),
                          child: ClipOval(
                            child: player.avatarUrl.isNotEmpty
                                ? NetImage(player.avatarUrl, width: 108, height: 108, fit: BoxFit.cover)
                                : Container(
                                    width: 108,
                                    height: 108,
                                    color: K.lime.withValues(alpha: .2),
                                    child: Center(
                                      child: Text(
                                        initialLetter,
                                        style: const TextStyle(color: K.lime, fontSize: 44, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        if (player.avatarUrl.isNotEmpty)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: K.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    player.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor.withValues(alpha: .5)),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(color: badgeColor == K.green ? K.lime : badgeColor, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (player.clubName.isNotEmpty || player.majorTeams.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_outlined, color: K.lime, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            player.clubName.isNotEmpty ? player.clubName : player.majorTeams,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: K.lime, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Overview Section
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
                      'Overview',
                      style: TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.3),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildOverviewItem(
                      icon: Icons.layers_outlined,
                      text: player.battingStyle.isNotEmpty ? player.battingStyle : 'Batting Style: N/A',
                    ),
                    _buildOverviewItem(
                      icon: Icons.access_time,
                      text: player.bowlingStyle.isNotEmpty && player.bowlingStyle != ' ' ? player.bowlingStyle : 'Bowling Style: N/A',
                    ),
                    _buildOverviewItem(
                      icon: Icons.location_on_outlined,
                      text: playerLocation.isNotEmpty ? playerLocation : 'Location: N/A',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Personal Profile Card
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
                      'Personal Profile',
                      style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Full Name', player.fullName),
                    _buildInfoRow('Date of Birth', player.dob.isNotEmpty ? player.dob.split('T').first : 'N/A'),
                    _buildInfoRow('Batting Style', player.battingStyle.isNotEmpty ? player.battingStyle : 'N/A'),
                    _buildInfoRow('Bowling Style', player.bowlingStyle.isNotEmpty ? player.bowlingStyle : 'N/A'),
                    _buildInfoRow('Playing Role', player.playingRole.isNotEmpty ? player.playingRole : role),
                    if (player.majorTeams.isNotEmpty) _buildInfoRow('Major Teams', player.majorTeams),
                    if (player.clubName.isNotEmpty) _buildInfoRow('Club Name', player.clubName),
                    if (playerLocation.isNotEmpty) _buildInfoRow('Location', playerLocation),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Career Statistics Sub-Tabs Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                tabs: const [
                  Tab(text: 'BATTING STATS'),
                  Tab(text: 'BOWLING STATS'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Stats Tab Content
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: K.green)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    final index = _tabController.index;
                    return index == 0 ? _buildBattingTable() : _buildBowlingTable();
                  },
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: K.dark, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: K.body, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattingTable() {
    if (_battingStats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Text('No batting records available.', style: TextStyle(color: K.body, fontSize: 13)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 14,
          headingRowHeight: 38,
          dataRowMinHeight: 36,
          headingTextStyle: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800),
          columns: const [
            DataColumn(label: Text('Season')),
            DataColumn(label: Text('Stage')),
            DataColumn(label: Text('Format')),
            DataColumn(label: Text('Mat')),
            DataColumn(label: Text('Inn')),
            DataColumn(label: Text('NO')),
            DataColumn(label: Text('Runs')),
            DataColumn(label: Text('HS')),
            DataColumn(label: Text('Avg')),
            DataColumn(label: Text('BF')),
            DataColumn(label: Text('SR')),
            DataColumn(label: Text('100s')),
            DataColumn(label: Text('50s')),
            DataColumn(label: Text('0s')),
            DataColumn(label: Text('4s')),
            DataColumn(label: Text('6s')),
            DataColumn(label: Text('Ct')),
            DataColumn(label: Text('St')),
          ],
          rows: _battingStats.map((s) {
            return DataRow(cells: [
              DataCell(Text('${s['Season'] ?? '-'}' , style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Stage'] ?? '-'}' , style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Format'] ?? '-'}' , style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Matches'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Inn'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['NotOut'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Runs'] ?? '0'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
              DataCell(Text('${s['HS'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Average'] ?? '-'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['BF'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['SR'] ?? '-'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Hundreds'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Fifties'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Zeros'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Fours'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Sixes'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Catches'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Stumpings'] ?? '0'}', style: const TextStyle(fontSize: 12))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBowlingTable() {
    if (_bowlingStats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Text('No bowling records available.', style: TextStyle(color: K.body, fontSize: 13)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 14,
          headingRowHeight: 38,
          dataRowMinHeight: 36,
          headingTextStyle: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800),
          columns: const [
            DataColumn(label: Text('Season')),
            DataColumn(label: Text('Stage')),
            DataColumn(label: Text('Format')),
            DataColumn(label: Text('Mat')),
            DataColumn(label: Text('Inn')),
            DataColumn(label: Text('Balls')),
            DataColumn(label: Text('Runs')),
            DataColumn(label: Text('Wkts')),
            DataColumn(label: Text('BBI')),
            DataColumn(label: Text('BBM')),
            DataColumn(label: Text('Avg')),
            DataColumn(label: Text('Econ')),
            DataColumn(label: Text('SR')),
            DataColumn(label: Text('4w')),
            DataColumn(label: Text('5w')),
          ],
          rows: _bowlingStats.map((s) {
            return DataRow(cells: [
              DataCell(Text('${s['Season'] ?? '-'}' , style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Stage'] ?? '-'}' , style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Format'] ?? '-'}' , style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Matches'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Inn'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Balls'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Runs'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Wickets'] ?? '0'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
              DataCell(Text('${s['BBI'] ?? '-'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['BBM'] ?? '-'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Average'] ?? '-'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Economy'] ?? '-'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['StrikeRate'] ?? '-'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Fourfor'] ?? '0'}', style: const TextStyle(fontSize: 12))),
              DataCell(Text('${s['Fivefor'] ?? '0'}', style: const TextStyle(fontSize: 12))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
