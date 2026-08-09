import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class InteractiveGoogleMap extends StatefulWidget {
  final String locationQuery;

  const InteractiveGoogleMap({
    super.key,
    required this.locationQuery,
  });

  @override
  State<InteractiveGoogleMap> createState() => _InteractiveGoogleMapState();
}

class _InteractiveGoogleMapState extends State<InteractiveGoogleMap> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initMapWebView();
  }

  void _initMapWebView() {
    final q = widget.locationQuery.trim().isNotEmpty ? widget.locationQuery.trim() : 'Pakistan';
    final queryEncoded = Uri.encodeComponent(q);

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body, html { margin: 0; padding: 0; height: 100%; width: 100%; overflow: hidden; background-color: #DAE5DD; }
    iframe { width: 100%; height: 100%; border: 0; }
  </style>
</head>
<body>
  <iframe src="https://maps.google.com/maps?q=$queryEncoded&t=&z=14&ie=UTF8&iwloc=&output=embed" allowfullscreen></iframe>
</body>
</html>
''';

    if (!kIsWeb) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFE4EAE5))
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (url) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              if (mounted) setState(() => _hasError = true);
            },
          ),
        )
        ..loadHtmlString(htmlContent);

      _controller = controller;
    }
  }

  Future<void> _launchExternalGoogleMaps() async {
    final q = widget.locationQuery.trim().isNotEmpty ? widget.locationQuery.trim() : 'Pakistan';
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || _controller == null || _hasError) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFDAE5DD),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, color: Color(0xFF004D2C), size: 40),
                  const SizedBox(height: 8),
                  Text(
                    widget.locationQuery,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF1E2923), fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _launchExternalGoogleMaps,
                    icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
                    label: const Text('Open Real Google Maps', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D2C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller!),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF004D2C)),
              ),
          ],
        ),
      ),
    );
  }
}
