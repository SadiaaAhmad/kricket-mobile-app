import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/services/players_api.dart';
import 'package:kricket_pk/widgets/interactive_google_map.dart';
import 'package:url_launcher/url_launcher.dart';

class GroundDetailScreen extends StatefulWidget {
  final int groundId;
  final String groundName;

  const GroundDetailScreen({
    super.key,
    required this.groundId,
    required this.groundName,
  });

  @override
  State<GroundDetailScreen> createState() => _GroundDetailScreenState();
}

class _GroundDetailScreenState extends State<GroundDetailScreen> {
  final _playersApi = PlayersApi();
  bool _isLoading = true;
  Map<String, dynamic>? _groundDetail;

  @override
  void initState() {
    super.initState();
    _fetchGroundData();
  }

  Future<void> _fetchGroundData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _playersApi.getGroundDetail(widget.groundId);
      if (mounted) {
        setState(() {
          _groundDetail = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openGoogleMaps(String locStr, String addressStr) async {
    String q = locStr.trim();
    if (q.isEmpty || q == '0' || q == 'null') {
      q = addressStr.trim();
    }
    if (q.isEmpty || q == 'N/A' || q == 'null') return;

    final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}');
    try {
      final launched = await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(mapsUrl, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final title = _groundDetail?['GroundName'] ?? widget.groundName;
    final address = '${_groundDetail?['Address'] ?? ''}'.trim();
    final city = '${_groundDetail?['CityName'] ?? ''}'.trim();
    final country = '${_groundDetail?['CountryName'] ?? 'Pakistan'}'.trim();
    final contactPerson = '${_groundDetail?['ContactPerson'] ?? ''}'.trim();
    final contactNo = '${_groundDetail?['ContactNo'] ?? ''}'.trim();
    final fee = '${_groundDetail?['Fee'] ?? ''}'.trim();
    final location = '${_groundDetail?['Location'] ?? ''}'.trim();

    final mapQuery = location.isNotEmpty && location != '0' ? location : (address.isNotEmpty ? '$address, $city' : '$title, $city, Pakistan');

    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        title: const Text(
          'Ground Details',
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
                          child: const Center(
                            child: Icon(Icons.stadium, color: K.green, size: 40),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.trim(),
                                style: const TextStyle(color: K.dark, fontSize: 19, fontWeight: FontWeight.w800, height: 1.2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${city.isNotEmpty ? city : 'Pakistan'} | Ground #${widget.groundId}',
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

                        // Row 1: Ground Name & ID
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'GROUND NAME',
                                value: title.trim(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'GROUND ID',
                                value: '${widget.groundId}',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 2: City & Country
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'CITY',
                                value: city.isNotEmpty ? city : 'N/A',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'COUNTRY',
                                value: country.isNotEmpty ? country : 'Pakistan',
                              ),
                            ),
                          ],
                        ),

                        if (contactPerson.isNotEmpty || contactNo.isNotEmpty || fee.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (contactPerson.isNotEmpty)
                                Expanded(
                                  child: _buildGridItem(
                                    title: 'CONTACT PERSON',
                                    value: contactPerson,
                                  ),
                                ),
                              if (contactNo.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildGridItem(
                                    title: 'CONTACT NO',
                                    value: contactNo,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Real Interactive Google Map Box
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
                          'Location Map',
                          style: TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.3),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Real Interactive Map Box Component
                        InteractiveGoogleMap(locationQuery: mapQuery),

                        const SizedBox(height: 12),

                        // Open in Google Maps Action Button
                        InkWell(
                          onTap: () => _openGoogleMaps(location, address.isNotEmpty ? address : title),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: K.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map_outlined, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Open in Google Maps',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.open_in_new, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
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
