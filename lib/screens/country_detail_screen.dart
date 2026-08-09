import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/directory_model.dart';
import 'package:kricket_pk/services/players_api.dart';
import 'package:kricket_pk/screens/franchise_detail_screen.dart';

class CountryDetailScreen extends StatefulWidget {
  final int countryCode;
  final String countryName;
  final String boardName;
  final String isoCode;

  const CountryDetailScreen({
    super.key,
    required this.countryCode,
    required this.countryName,
    this.boardName = '',
    this.isoCode = '',
  });

  @override
  State<CountryDetailScreen> createState() => _CountryDetailScreenState();
}

class _CountryDetailScreenState extends State<CountryDetailScreen> {
  final _playersApi = PlayersApi();
  bool _isLoading = true;
  List<DirectoryItem> _franchises = [];

  @override
  void initState() {
    super.initState();
    _fetchCountryData();
  }

  Future<void> _fetchCountryData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _playersApi.getFranchisesByCountry(widget.countryCode);
      if (mounted) {
        setState(() {
          _franchises = res;
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
    final initialLetter = widget.countryName.trim().isNotEmpty ? widget.countryName.trim()[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        title: const Text(
          'Country Board Details',
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
                                widget.countryName.trim(),
                                style: const TextStyle(color: K.dark, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.boardName.isNotEmpty ? widget.boardName : 'ICC Country Member Board',
                                style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w700),
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

                        // Row 1: Country Name & Code
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'COUNTRY NAME',
                                value: widget.countryName.trim(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'COUNTRY CODE',
                                value: '${widget.countryCode}',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 2: Board Name & ISO Code
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'CRICKET BOARD',
                                value: widget.boardName.isNotEmpty ? widget.boardName : 'ICC Board',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'ISO CODE',
                                value: widget.isoCode.isNotEmpty ? widget.isoCode : 'N/A',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Country Franchises Header
                  Row(
                    children: [
                      const Icon(Icons.sports_cricket, color: K.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Country Franchises (${_franchises.length})',
                        style: const TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_franchises.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Text('No national franchises listed for this country.', style: TextStyle(color: K.body, fontSize: 13)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _franchises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _franchises[index];
                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FranchiseDetailScreen(franchiseId: item.id, franchiseName: item.title),
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
                                const Icon(Icons.sports_cricket_outlined, color: K.green, size: 20),
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
}
