import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/services/players_api.dart';
import 'package:kricket_pk/screens/district_detail_screen.dart';
import 'package:kricket_pk/screens/region_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kricket_pk/widgets/interactive_google_map.dart';
import 'package:kricket_pk/screens/city_detail_screen.dart';
import 'package:kricket_pk/screens/country_detail_screen.dart';

class ClubDetailScreen extends StatefulWidget {
  final int clubId;
  final String clubName;

  const ClubDetailScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  final _playersApi = PlayersApi();
  bool _isLoading = true;
  Map<String, dynamic>? _clubDetail;

  @override
  void initState() {
    super.initState();
    _fetchClubData();
  }

  Future<void> _fetchClubData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _playersApi.getClubDetail(widget.clubId);
      if (mounted) {
        setState(() {
          _clubDetail = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openUrl(String urlStr) async {
    final s = urlStr.trim();
    if (s.isEmpty || s == 'N/A' || s == 'null') return;
    String formatted = s;
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }
    final uri = Uri.parse(formatted);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
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
    } catch (_) {
      try {
        await launchUrl(mapsUrl, mode: LaunchMode.inAppWebView);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final title = _clubDetail?['ClubName'] ?? widget.clubName;
    final shortName = _clubDetail?['ShortName'] ?? '';
    final assocName = _clubDetail?['AssociationName'] ?? '';
    final assocId = _clubDetail?['AssociationId'] ?? 0;
    final regionName = _clubDetail?['RegionName'] ?? '';
    final regionId = _clubDetail?['RegionId'] ?? 0;

    final statusVal = '${_clubDetail?['ClubStatus'] ?? _clubDetail?['Status'] ?? _clubDetail?['Type'] ?? ''}'.trim();
    final isRegistered = _clubDetail?['Registered'] == 1 || _clubDetail?['Valid'] == 1;

    String badgeText = 'REGISTERED';
    Color badgeColor = K.green;
    if (statusVal.toLowerCase().contains('community') || _clubDetail?['Registered'] == 0 || !isRegistered) {
      badgeText = 'COMMUNITY';
      badgeColor = Colors.orange.shade800;
    }

    final city = _clubDetail?['CityName'] ?? _clubDetail?['city'] ?? '';
    final country = _clubDetail?['CountryName'] ?? _clubDetail?['country'] ?? '';
    final captain = _clubDetail?['Captain'] ?? 0;
    final location = _clubDetail?['Location'] ?? '';

    final contactNo = '${_clubDetail?['ContactNo'] ?? _clubDetail?['Phone'] ?? _clubDetail?['PresidentContact'] ?? ''}'.trim();
    final email = '${_clubDetail?['Email'] ?? ''}'.trim();
    final website = '${_clubDetail?['Website'] ?? ''}'.trim();
    final fbPage = '${_clubDetail?['FBPage'] ?? _clubDetail?['Facebook'] ?? ''}'.trim();

    final president = '${_clubDetail?['President'] ?? ''}'.trim();
    final coach = '${_clubDetail?['Coach'] ?? ''}'.trim();
    final treasurer = '${_clubDetail?['Treasurer'] ?? ''}'.trim();
    final secretary = '${_clubDetail?['Secretary'] ?? ''}'.trim();
    final address = '${_clubDetail?['Address'] ?? ''}'.trim();
    final description = '${_clubDetail?['Description'] ?? ''}'.trim();

    final hasOfficials = president.isNotEmpty ||
        coach.isNotEmpty ||
        treasurer.isNotEmpty ||
        secretary.isNotEmpty ||
        address.isNotEmpty ||
        contactNo.isNotEmpty ||
        email.isNotEmpty ||
        website.isNotEmpty ||
        fbPage.isNotEmpty ||
        description.isNotEmpty;

    final initialLetter = title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        title: const Text(
          'Club Details',
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
                        // Left Logo Box with Status Ribbon
                        Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F7F3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Center(
                                child: Text(
                                  initialLetter,
                                  style: const TextStyle(color: K.green, fontSize: 44, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                                ),
                                child: Text(
                                  badgeText,
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.trim().isNotEmpty ? title.trim() : 'Club #${widget.clubId}',
                                style: const TextStyle(color: K.dark, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${shortName.toString().isNotEmpty ? shortName : 'Club'} | Club #${widget.clubId}',
                                style: const TextStyle(color: K.body, fontSize: 12),
                              ),
                              if (assocName.toString().trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: assocId > 0
                                      ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DistrictDetailScreen(
                                                associationId: assocId,
                                                associationName: assocName.toString(),
                                              ),
                                            ),
                                          )
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: K.green.withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: K.green.withValues(alpha: .3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_city, color: K.green, size: 14),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            assocName.toString().trim(),
                                            style: const TextStyle(color: K.green, fontSize: 12, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward_ios, color: K.green, size: 11),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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

                        // Row 1: District & Region
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'DISTRICT',
                                child: InkWell(
                                  onTap: assocId > 0
                                      ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DistrictDetailScreen(
                                                associationId: assocId,
                                                associationName: assocName.toString(),
                                              ),
                                            ),
                                          )
                                      : null,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          assocName.toString().trim().isNotEmpty ? assocName.toString().trim() : 'N/A',
                                          style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      if (assocId > 0) const Icon(Icons.arrow_forward_ios, color: K.green, size: 11),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'REGION',
                                child: InkWell(
                                  onTap: regionId > 0
                                      ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => RegionDetailScreen(
                                                regionId: regionId,
                                                regionName: regionName.toString(),
                                              ),
                                            ),
                                          )
                                      : null,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          regionName.toString().trim().isNotEmpty ? regionName.toString().trim() : 'N/A',
                                          style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      if (regionId > 0) const Icon(Icons.arrow_forward_ios, color: K.green, size: 11),
                                    ],
                                  ),
                                ),
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
                                value: badgeText,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 3: City & Country
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'CITY',
                                child: InkWell(
                                  onTap: city.toString().trim().isNotEmpty
                                      ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CityDetailScreen(
                                                cityId: _clubDetail?['CityId'] ?? _clubDetail?['cityid'] ?? 0,
                                                cityName: city.toString().trim(),
                                              ),
                                            ),
                                          )
                                      : null,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          city.toString().trim().isNotEmpty ? city.toString().trim() : 'N/A',
                                          style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      if (city.toString().trim().isNotEmpty) const Icon(Icons.arrow_forward_ios, color: K.green, size: 11),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGridItem(
                                title: 'COUNTRY',
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CountryDetailScreen(
                                        countryCode: _clubDetail?['CountryCode'] ?? _clubDetail?['countryid'] ?? 92,
                                        countryName: country.toString().trim().isNotEmpty ? country.toString().trim() : 'Pakistan',
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          country.toString().trim().isNotEmpty ? country.toString().trim() : 'Pakistan',
                                          style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, color: K.green, size: 11),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 4: Captain
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                title: 'CAPTAIN',
                                value: '$captain',
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Officials Card (ONLY shown if non-empty official/contact data exists!)
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
                            'Club Information & Contacts',
                            style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          if (contactNo.isNotEmpty) _buildInfoRow('Contact No', contactNo),
                          if (email.isNotEmpty) _buildInfoRow('Email', email),
                          if (website.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 100,
                                    child: Text('Website', style: TextStyle(color: K.body, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _openUrl(website),
                                      child: Row(
                                        children: [
                                          Text(website, style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w700)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.open_in_new, color: K.green, size: 12),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (fbPage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 100,
                                    child: Text('Facebook', style: TextStyle(color: K.body, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _openUrl(fbPage),
                                      child: Row(
                                        children: [
                                          Text(fbPage, style: const TextStyle(color: K.green, fontSize: 13, fontWeight: FontWeight.w700)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.open_in_new, color: K.green, size: 12),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (president.isNotEmpty) _buildInfoRow('President', president),
                          if (secretary.isNotEmpty) _buildInfoRow('Secretary', secretary),
                          if (coach.isNotEmpty) _buildInfoRow('Coach', coach),
                          if (treasurer.isNotEmpty) _buildInfoRow('Treasurer', treasurer),
                          if (address.isNotEmpty) _buildInfoRow('Address', address),
                          if (description.isNotEmpty) _buildInfoRow('Description', description),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Location Map Card Section
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

                        // Real Interactive Google Map Box Component
                        InteractiveGoogleMap(
                          locationQuery: location.toString().isNotEmpty && location.toString() != '0'
                              ? location.toString()
                              : (address.isNotEmpty ? address : (city.isNotEmpty ? city : 'Pakistan')),
                        ),

                        const SizedBox(height: 12),

                        // Open in Google Maps Action Link
                        InkWell(
                          onTap: () => _openGoogleMaps(location.toString(), address),
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

  Widget _buildInfoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFC7D8CB)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path1 = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width, size.height * 0.6);
    canvas.drawPath(path1, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.3, 0)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.7, size.width * 0.7, size.height);
    canvas.drawPath(path2, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
