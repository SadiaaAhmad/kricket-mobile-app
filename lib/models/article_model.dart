class ArticleData {
  const ArticleData({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.image,
    required this.date,
    required this.readTime,
    required this.body,
    required this.source,
  });

  final String id;
  final String category;
  final String title;
  final String summary;
  final String image;
  final String date;
  final String readTime;
  final List<String> body;
  final String source;

  factory ArticleData.fromJson(Map<String, dynamic> json) => ArticleData(
        id: cleanText(json['id'] as String? ?? ''),
        category: cleanText(json['category'] as String? ?? ''),
        title: cleanText(json['title'] as String? ?? ''),
        summary: cleanText(json['summary'] as String? ?? ''),
        image: json['image_url'] as String? ?? '',
        date: json['published_at'] as String? ?? '',
        readTime: json['read_time'] as String? ?? '',
        body: (json['body'] as List<dynamic>? ?? [])
            .map((e) => cleanText(e.toString()))
            .toList(),
        source: cleanText(json['source'] as String? ?? ''),
      );

  factory ArticleData.fromBackendJson(Map<String, dynamic> json) {
    final imagePath = (json['Image'] as String? ?? '').trim();
    final imageUrl = imagePath.isEmpty
        ? 'assets/images/cricket_stadium.png'
        : 'https://kricket.pk/images/${imagePath.replaceFirst(RegExp(r'^/+'), '')}';
    
    // Get the full article content and clean HTML
    final rawContent = json['Content'] as String? ?? '';
    
    // Replace block-level HTML tags (<p>, </p>, <pr>, </pr>, <br>, <br/>, <div>, etc.) with double newlines
    final contentWithBreaks = rawContent.replaceAll(
      RegExp(r'</?(?:p|pr|br|div|tr|li)\s*/?>', caseSensitive: false),
      '\n\n',
    );
    
    // Remove all remaining HTML tags
    final stripped = contentWithBreaks.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Clean text and decode HTML entities for each paragraph
    List<String> paragraphs = stripped
        .split(RegExp(r'\n+'))
        .map((p) => cleanText(p))
        .where((p) => p.isNotEmpty)
        .toList();
        
    if (paragraphs.isEmpty) {
      paragraphs = ['Article content is not available yet.'];
    }
    
    final summary = paragraphs.first;
    
    return ArticleData(
      id: '${json['ArticleId']}',
      category: cleanText(json['Title'] as String? ?? 'CRICKET NEWS').toUpperCase(),
      title: cleanText(json['Heading'] as String? ?? 'Kricket.pk article'),
      summary: summary,
      image: imageUrl,
      date: formatBackendDate(json['Dated'] as String?),
      readTime: '3 min read',
      body: paragraphs,
      source: cleanText(json['Writer'] as String? ?? 'kricket.pk'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'summary': summary,
        'image_url': image,
        'published_at': date,
        'read_time': readTime,
        'body': body,
        'source': source,
      };
}

String cleanText(String? val) {
  if (val == null || val.isEmpty) return '';
  String text = val;
  // Replace HTML paragraph and line break tags with space
  text = text.replaceAll(RegExp(r'</?(?:p|pr|br|div|tr|li)\s*/?>', caseSensitive: false), ' ');
  // Remove remaining HTML tags
  text = text.replaceAll(RegExp(r'<[^>]*>', caseSensitive: false), '');
  // Decode HTML entities
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&ndash;', '–')
      .replaceAll('&mdash;', '—')
      .replaceAll('&hellip;', '...');
  return text.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String formatBackendDate(String? raw) {
  if (raw == null || raw.isEmpty) return 'TBA';
  try {
    final dt = DateTime.parse(raw).toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final hourNum = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day}, ${dt.year} • $hourNum:$minStr $ampm';
  } catch (_) {
    return raw;
  }
}
