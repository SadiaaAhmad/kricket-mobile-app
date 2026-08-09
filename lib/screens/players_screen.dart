import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/player_model.dart';
import 'package:kricket_pk/models/directory_model.dart';
import 'package:kricket_pk/services/players_api.dart';
import 'package:kricket_pk/widgets/net_image.dart';
import 'package:kricket_pk/screens/player_detail_screen.dart';
import 'package:kricket_pk/screens/district_detail_screen.dart';
import 'package:kricket_pk/screens/club_detail_screen.dart';
import 'package:kricket_pk/screens/team_detail_screen.dart';
import 'package:kricket_pk/screens/region_detail_screen.dart';
import 'package:kricket_pk/screens/department_detail_screen.dart';
import 'package:kricket_pk/screens/franchise_detail_screen.dart';
import 'package:kricket_pk/screens/ground_detail_screen.dart';
import 'package:kricket_pk/screens/city_detail_screen.dart';
import 'package:kricket_pk/screens/country_detail_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _playersApi = PlayersApi();
  final _searchController = TextEditingController();
  late final ScrollController _scrollController;
  late final ScrollController _sectionScrollController;
  late final ScrollController _roleScrollController;

  String _selectedSection = 'Players';
  String _selectedRole = 'All';
  String _searchQuery = '';

  // Data states
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMoreData = true;

  final List<PlayerData> _players = [];
  final List<PlayerData> _trendingPlayers = [];
  final List<DirectoryItem> _allRawDirectoryItems = [];
  final List<DirectoryItem> _directoryItems = [];

  static const _sections = [
    'Players',
    'District',
    'Region',
    'Department',
    'Franchise',
    'Club',
    'Team',
    'City',
    'Country',
    'Ground',
  ];

  static const _roles = [
    'All',
    'Batters',
    'Bowlers',
    'All-rounders',
    'Keeper-Batters',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _sectionScrollController = ScrollController();
    _roleScrollController = ScrollController();
    _loadCurrentSectionData();
    _loadTrendingPlayers();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _sectionScrollController.dispose();
    _roleScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingPlayers() async {
    try {
      final results = await Future.wait([
        _playersApi.searchPlayersByName('Babar'),
        _playersApi.searchPlayersByName('Shaheen'),
        _playersApi.searchPlayersByName('Rizwan'),
      ]);
      final list = <PlayerData>[];
      for (final res in results) {
        if (res.isNotEmpty) list.add(res.first);
      }
      if (mounted && list.isNotEmpty) {
        setState(() {
          _trendingPlayers.clear();
          _trendingPlayers.addAll(list);
        });
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoading && _hasMoreData && _searchQuery.isEmpty) {
        _loadCurrentSectionData(reset: false);
      }
    }
  }

  Future<void> _loadCurrentSectionData({bool reset = true}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (reset) {
      _currentPage = 1;
      _hasMoreData = true;
      if (_selectedSection == 'Players') {
        _players.clear();
      } else {
        _allRawDirectoryItems.clear();
        _directoryItems.clear();
      }
    }

    try {
      if (_selectedSection == 'Players') {
        final newPlayers = await _playersApi.getPlayers(page: _currentPage, perPage: 20);
        if (newPlayers.isEmpty) {
          _hasMoreData = false;
        } else {
          _players.addAll(newPlayers);
          _currentPage++;
        }
      } else {
        // Fast local chunk slicing for instant response across ALL directory sections
        if (_allRawDirectoryItems.isEmpty) {
          List<DirectoryItem> fetched = [];
          if (_selectedSection == 'District') {
            fetched = await _playersApi.getDistricts();
          } else if (_selectedSection == 'Region') {
            fetched = await _playersApi.getRegions();
          } else if (_selectedSection == 'Department') {
            fetched = await _playersApi.getDepartments();
          } else if (_selectedSection == 'Franchise') {
            fetched = await _playersApi.getFranchises();
          } else if (_selectedSection == 'Club') {
            fetched = await _playersApi.getClubs(page: 1, perPage: 200);
          } else if (_selectedSection == 'Team') {
            fetched = await _playersApi.getTeams(page: 1, perPage: 200);
          } else if (_selectedSection == 'City') {
            fetched = await _playersApi.getCities();
          } else if (_selectedSection == 'Country') {
            fetched = await _playersApi.getCountries();
          } else if (_selectedSection == 'Ground') {
            fetched = await _playersApi.getGrounds(page: 1, perPage: 200);
          }
          _allRawDirectoryItems.addAll(fetched);
        }

        const pageSize = 20;
        final startIndex = (_currentPage - 1) * pageSize;
        if (startIndex >= _allRawDirectoryItems.length) {
          _hasMoreData = false;
        } else {
          final nextChunk = _allRawDirectoryItems.skip(startIndex).take(pageSize).toList();
          _directoryItems.addAll(nextChunk);
          _currentPage++;
          if (_directoryItems.length >= _allRawDirectoryItems.length) {
            _hasMoreData = false;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performBackendSearch(String query) async {
    final q = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (q.isEmpty) return;
    try {
      final searchResults = await _playersApi.searchPlayersByName(q);
      if (searchResults.isNotEmpty && mounted) {
        setState(() {
          for (final p in searchResults) {
            if (!_players.any((existing) => existing.playerId == p.playerId)) {
              _players.insert(0, p);
            }
          }
        });
      }
    } catch (_) {}
  }

  List<PlayerData> get _filteredPlayers {
    if (_searchQuery.isEmpty && _selectedRole == 'All') return _players;

    final q = _searchQuery.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    return _players.where((p) {
      final pName = p.fullName.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final pTeams = p.majorTeams.toLowerCase();
      final pClub = p.clubName.toLowerCase();

      final matchesSearch = q.isEmpty || pName.contains(q) || pTeams.contains(q) || pClub.contains(q);
      if (!matchesSearch) return false;

      final roleStr = '${p.playingRole} ${p.derivedRole} ${p.battingStyle} ${p.bowlingStyle}'.toLowerCase();

      if (_selectedRole == 'Batters') {
        return roleStr.contains('bat') || roleStr.contains('batsman') || roleStr.contains('batter');
      } else if (_selectedRole == 'Bowlers') {
        return roleStr.contains('bowl') || roleStr.contains('bowler');
      } else if (_selectedRole == 'All-rounders') {
        return roleStr.contains('all') || (p.battingStyle.isNotEmpty && p.bowlingStyle.isNotEmpty && p.bowlingStyle != ' ');
      } else if (_selectedRole == 'Keeper-Batters') {
        return roleStr.contains('keeper') || roleStr.contains('wk') || roleStr.contains('wicket');
      }
      return true;
    }).toList();
  }

  List<DirectoryItem> get _filteredDirectoryItems {
    final source = _searchQuery.isNotEmpty ? _allRawDirectoryItems : _directoryItems;
    if (_searchQuery.isEmpty) return source;

    final q = _searchQuery.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return source.where((item) {
      final t = item.title.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final s = item.subtitle.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      return t.contains(q) || s.contains(q);
    }).toList();
  }

  String get _sectionTitle {
    if (_selectedSection == 'Players') return 'All Players';
    if (_selectedSection == 'City') return 'All Cities';
    if (_selectedSection == 'Country') return 'All Countries';
    if (_selectedSection == 'Franchise') return 'All Franchises';
    return 'All ${_selectedSection}s';
  }

  void _onDirectoryCardTapped(DirectoryItem item) {
    if (item.category == 'Club') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubDetailScreen(clubId: item.id, clubName: item.title),
        ),
      );
    } else if (item.category == 'Team') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamDetailScreen(teamId: item.id, teamName: item.title),
        ),
      );
    } else if (item.category == 'Region') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegionDetailScreen(regionId: item.id, regionName: item.title),
        ),
      );
    } else if (item.category == 'District') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DistrictDetailScreen(associationId: item.id, associationName: item.title),
        ),
      );
    } else if (item.category == 'Department') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepartmentDetailScreen(departmentId: item.id, departmentName: item.title),
        ),
      );
    } else if (item.category == 'Franchise') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FranchiseDetailScreen(franchiseId: item.id, franchiseName: item.title),
        ),
      );
    } else if (item.category == 'Ground') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroundDetailScreen(groundId: item.id, groundName: item.title),
        ),
      );
    } else if (item.category == 'City') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CityDetailScreen(cityId: item.id, cityName: item.title),
        ),
      );
    } else if (item.category == 'Country') {
      final board = '${item.rawJson['BoardName'] ?? ''}'.trim();
      final iso = '${item.rawJson['ISOCode2'] ?? item.rawJson['ISOCode3'] ?? ''}'.trim();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CountryDetailScreen(
            countryCode: item.id,
            countryName: item.title,
            boardName: board,
            isoCode: iso,
          ),
        ),
      );
    } else {
      _showDirectoryDetailSheet(item);
    }
  }

  void _showDirectoryDetailSheet(DirectoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + safeBottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0x1A004D2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        item.title.isNotEmpty ? item.title[0].toUpperCase() : 'D',
                        style: const TextStyle(color: K.green, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item.subtitle,
                          style: const TextStyle(color: K.body, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              ...item.rawJson.entries.map((e) {
                final val = '${e.value}'.trim();
                if (val.isEmpty || val == 'null') return const SizedBox.shrink();
                return _buildDetailRow(e.key, val);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: K.body, fontSize: 13, fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 48 + safeBottom + 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Directory Page Header Title
          const Text(
            'Players Directory',
            style: TextStyle(
              color: K.dark,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedSection == 'Players'
                ? 'Search and explore cricket players across Pakistan & world.'
                : 'Browse all cricket ${_selectedSection.toLowerCase()}s and associations.',
            style: const TextStyle(color: K.body, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Search Bar Input (Instant, Case-Insensitive, Space-Normalized)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                setState(() => _searchQuery = v);
                if (_selectedSection == 'Players' && v.trim().length >= 3) {
                  _performBackendSearch(v.trim());
                }
              },
              decoration: InputDecoration(
                icon: const Icon(Icons.search, color: K.body, size: 20),
                hintText: 'Search ${_selectedSection.toLowerCase()}s...',
                hintStyle: const TextStyle(color: K.body, fontSize: 14),
                border: InputBorder.none,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: K.body),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Top Directory Category Chips Bar (With Auto-Scroll on Tap)
          SizedBox(
            height: 38,
            child: ListView.separated(
              controller: _sectionScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _sections.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final section = _sections[index];
                final isSelected = section == _selectedSection;
                return ChoiceChip(
                  label: Text(section),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected && section != _selectedSection) {
                      setState(() {
                        _selectedSection = section;
                        _searchController.clear();
                        _searchQuery = '';
                      });

                      if (_sectionScrollController.hasClients) {
                        final targetOffset = (index * 85.0).clamp(
                          0.0,
                          _sectionScrollController.position.maxScrollExtent,
                        );
                        _sectionScrollController.animateTo(
                          targetOffset,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }

                      _loadCurrentSectionData(reset: true);
                    }
                  },
                  selectedColor: K.green,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : K.dark,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? K.green : Colors.grey.shade300),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),

          // Sub-Role Chips (Only for Players section, with Auto-Scroll on Tap)
          if (_selectedSection == 'Players') ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: ListView.separated(
                controller: _roleScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: _roles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  final isSelected = role == _selectedRole;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedRole = role);

                      if (_roleScrollController.hasClients) {
                        final targetOffset = (index * 95.0).clamp(
                          0.0,
                          _roleScrollController.position.maxScrollExtent,
                        );
                        _roleScrollController.animateTo(
                          targetOffset,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(17),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? K.lime : Colors.white,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: isSelected ? K.lime : Colors.grey.shade300),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: isSelected ? K.dark : K.body,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Trending Players Hero Section (When search is empty)
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.trending_up, color: K.green, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Trending Players',
                    style: TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: _trendingPlayers.isNotEmpty
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _trendingPlayers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final player = _trendingPlayers[index];
                          return _buildRealTrendingCard(player, index + 1);
                        },
                      )
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildTrendingCard(
                            name: 'Babar Azam',
                            role: 'BATTER • PAKISTAN',
                            badge: '#1',
                            gradientColors: [const Color(0xFF004D2C), const Color(0xFF007A46)],
                          ),
                          const SizedBox(width: 12),
                          _buildTrendingCard(
                            name: 'Shaheen Afridi',
                            role: 'BOWLER • PAKISTAN',
                            badge: '🔥',
                            gradientColors: [const Color(0xFF1E3A2B), const Color(0xFF2C5E43)],
                          ),
                        ],
                      ),
              ),
            ],
          ],

          const SizedBox(height: 20),

          // Main Section Title (With Corrected Plural Grammar!)
          Text(
            _sectionTitle,
            style: const TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          // Initial Loading Spinner
          if (_isLoading && (_players.isEmpty && _directoryItems.isEmpty))
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: K.green),
              ),
            )
          else if (_selectedSection == 'Players') ...[
            // Players Grid View
            if (_filteredPlayers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No players found matching your criteria.',
                    style: TextStyle(color: K.body, fontSize: 14),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredPlayers.length,
                itemBuilder: (context, index) {
                  final player = _filteredPlayers[index];
                  return _buildPlayerCard(player);
                },
              ),

            if (_isLoading && _players.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: K.green)),
              ),
          ] else if (_selectedSection == 'District') ...[
            // District Cards Section (Rebuilt with Sleek Action Buttons & Badges!)
            if (_filteredDirectoryItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No district associations found.',
                    style: TextStyle(color: K.body, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredDirectoryItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _filteredDirectoryItems[index];
                  return _buildDistrictCard(item);
                },
              ),

            if (_isLoading && _directoryItems.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: K.green)),
              ),
          ] else ...[
            // Generic Directory Items View (With Infinite Scroll Pagination for ALL categories!)
            if (_filteredDirectoryItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No ${_selectedSection.toLowerCase()}s found.',
                    style: const TextStyle(color: K.body, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredDirectoryItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _filteredDirectoryItems[index];
                  return _buildDirectoryCard(item);
                },
              ),

            if (_isLoading && _directoryItems.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: K.green)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRealTrendingCard(PlayerData player, int rank) {
    final role = player.derivedRole.toUpperCase();
    final country = player.country.isNotEmpty ? player.country.toUpperCase() : 'PAKISTAN';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerDetailScreen(playerId: player.playerId, initialData: player),
        ),
      ),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF004D2C), Color(0xFF007A46)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF004D2C).withValues(alpha: .3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$role • $country',
                  style: const TextStyle(color: K.lime, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5),
                ),
                const SizedBox(height: 4),
                Text(
                  player.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: K.lime,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingCard({
    required String name,
    required String role,
    required String badge,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: .3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                role,
                style: const TextStyle(color: K.lime, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: K.lime,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badge,
                  style: const TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerData player) {
    final role = player.derivedRole;
    Color badgeColor = K.green;
    if (role.toLowerCase().contains('bowl')) badgeColor = Colors.red.shade700;
    if (role.toLowerCase().contains('all')) badgeColor = Colors.amber.shade800;
    if (role.toLowerCase().contains('keeper')) badgeColor = Colors.blue.shade700;

    final initialLetter = player.fullName.isNotEmpty ? player.fullName[0].toUpperCase() : 'P';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerDetailScreen(playerId: player.playerId, initialData: player),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0x1A004D2C),
              child: ClipOval(
                child: player.avatarUrl.isNotEmpty
                    ? NetImage(player.avatarUrl, width: 68, height: 68)
                    : Container(
                        width: 68,
                        height: 68,
                        color: K.green.withValues(alpha: .15),
                        child: Center(
                          child: Text(
                            initialLetter,
                            style: const TextStyle(color: K.green, fontSize: 26, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              player.fullName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: K.dark, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              player.clubName.isNotEmpty ? player.clubName : (player.majorTeams.isNotEmpty ? player.majorTeams : 'Pakistan'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: K.body, fontSize: 11),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                role.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictCard(DirectoryItem item) {
    final title = item.title;
    final region = item.rawJson['RegionName'] ?? '';
    final regionId = item.rawJson['RegionId'] ?? 0;
    final letter = title.isNotEmpty ? title[0].toUpperCase() : 'D';
    final assocId = item.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: K.green.withValues(alpha: .2)),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: const TextStyle(color: K.green, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: K.dark, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    if (region.toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: regionId > 0
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegionDetailScreen(regionId: regionId, regionName: region.toString()),
                                  ),
                                )
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Region: ${region.toString().trim()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, color: K.green, size: 10),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Action Buttons with Overflow-Protected Layout
          Row(
            children: [
              // 1. View District Button
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DistrictDetailScreen(associationId: assocId, associationName: title, initialTabIndex: 0),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                    decoration: BoxDecoration(
                      color: K.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'View District',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 2. Clubs Badge Button
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DistrictDetailScreen(associationId: assocId, associationName: title, initialTabIndex: 0),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: K.green.withValues(alpha: .4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, color: K.green, size: 13),
                        SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Clubs',
                              style: TextStyle(color: K.green, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 3. Teams Badge Button
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DistrictDetailScreen(associationId: assocId, associationName: title, initialTabIndex: 1),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: K.green.withValues(alpha: .4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_outlined, color: K.green, size: 13),
                        SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Teams',
                              style: TextStyle(color: K.green, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryCard(DirectoryItem item) {
    IconData iconData = Icons.folder_outlined;
    Color iconBg = const Color(0x1A004D2C);

    if (item.category == 'Club') {
      iconData = Icons.shield_outlined;
    } else if (item.category == 'Team') {
      iconData = Icons.groups_outlined;
    } else if (item.category == 'Region') {
      iconData = Icons.landscape_outlined;
    } else if (item.category == 'City') {
      iconData = Icons.location_city_outlined;
    } else if (item.category == 'Country') {
      iconData = Icons.public;
    } else if (item.category == 'Ground') {
      iconData = Icons.stadium_outlined;
    } else if (item.category == 'Department') {
      iconData = Icons.business_outlined;
    } else if (item.category == 'Franchise') {
      iconData = Icons.sports_cricket_outlined;
    }

    return InkWell(
      onTap: () => _onDirectoryCardTapped(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(iconData, color: K.green, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: K.body, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F7F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 12, color: K.green),
            ),
          ],
        ),
      ),
    );
  }
}
