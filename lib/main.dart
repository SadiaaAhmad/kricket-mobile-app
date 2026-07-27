import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const KricketApp());

class K {
  static const dark = Color(0xFF00341C);
  static const green = Color(0xFF004D2C);
  static const lime = Color(0xFFC1F100);
  static const limeText = Color(0xFF506600);
  static const ink = Color(0xFF1A1C1C);
  static const body = Color(0xFF404942);
  static const bg = Color(0xFFF9F9F9);
}

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
        id: json['id'] as String,
        category: json['category'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        image: json['image_url'] as String,
        date: json['published_at'] as String,
        readTime: json['read_time'] as String,
        body: (json['body'] as List<dynamic>).cast<String>(),
        source: json['source'] as String,
      );

  factory ArticleData.fromBackendJson(Map<String, dynamic> json) {
    final imagePath = (json['Image'] as String? ?? '').trim();
    final imageUrl = imagePath.isEmpty
        ? 'assets/images/cricket_stadium.png'
        : 'https://kricket.pk/images/${imagePath.replaceFirst(RegExp(r'^/+'), '')}';
    
    // Get the full article content and clean HTML
    final rawContent = json['Content'] as String? ?? '';
    final cleanedContent = _cleanText(rawContent);
    
    // Split by paragraph breaks (multiple newlines or by </p><p> patterns)
    List<String> paragraphs = [];
    if (cleanedContent.isEmpty) {
      paragraphs = ['Article content is not available yet.'];
    } else {
      paragraphs = cleanedContent
          .split(RegExp(r'\n+'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
    }
    
    // Use first paragraph as summary
    final summary = paragraphs.isNotEmpty ? paragraphs.first : cleanedContent;
    
    return ArticleData(
      id: '${json['ArticleId']}',
      category: _cleanText(json['Title'] as String? ?? 'CRICKET NEWS').toUpperCase(),
      title: _cleanText(json['Heading'] as String? ?? 'Kricket.pk article'),
      summary: summary,
      image: imageUrl,
      date: _formatBackendDate(json['Dated'] as String?),
      readTime: '3 min read',
      body: paragraphs,
      source: _cleanText(json['Writer'] as String? ?? 'kricket.pk'),
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

String _cleanText(String? val) {
  if (val == null) return '';
  return val.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _formatBackendDate(String? raw) {
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

class MatchInningsSummary {
  const MatchInningsSummary({
    required this.innings,
    required this.score,
    required this.overs,
    required this.wickets,
    required this.battingTeamName,
    required this.bowlingTeamName,
  });

  final int innings;
  final int score;
  final String overs;
  final int wickets;
  final String battingTeamName;
  final String bowlingTeamName;

  factory MatchInningsSummary.fromJson(Map<String, dynamic> json) => MatchInningsSummary(
        innings: json['Innings'] as int? ?? 1,
        score: json['Score'] as int? ?? 0,
        overs: '${json['Overs'] ?? '0'}',
        wickets: json['Wickets'] as int? ?? 0,
        battingTeamName: _cleanText(json['BattingTeamName'] as String? ?? ''),
        bowlingTeamName: _cleanText(json['BowlingTeamName'] as String? ?? ''),
      );
}

class MatchData {
  const MatchData({
    required this.matchNo,
    required this.team1Name,
    required this.team2Name,
    required this.date,
    required this.groundName,
    required this.format,
    required this.tournament,
    required this.resultDetail,
    required this.team1,
    required this.team2,
    required this.status,
    this.manOfMatchName,
    this.cityName,
    this.countryName,
    this.season,
    this.inningsSummaries = const [],
  });

  final int matchNo;
  final String team1Name;
  final String team2Name;
  final String date;
  final String groundName;
  final String format;
  final String tournament;
  final String? resultDetail;
  final int team1;
  final int team2;
  final String status; // 'S' = Scheduled/Upcoming, 'L' = Live, 'P' = Played/Completed
  final String? manOfMatchName;
  final String? cityName;
  final String? countryName;
  final String? season;
  final List<MatchInningsSummary> inningsSummaries;

  factory MatchData.fromJson(Map<String, dynamic> json) {
    final live = (json['Live'] as String? ?? '').trim();
    final resultDetailRaw = json['ResultDetail'] as String?;
    final resultDetail = resultDetailRaw != null && resultDetailRaw.isNotEmpty ? _cleanText(resultDetailRaw) : null;
    
    String status = json['Status'] as String? ?? '';
    if (status.isEmpty) {
      if (live.toLowerCase() == 'live') {
        status = 'L';
      } else if (resultDetail != null && resultDetail.isNotEmpty) {
        status = 'P';
      } else {
        status = 'S';
      }
    }

    final rawInnings = json['Innings'] as List<dynamic>?;
    final inningsSummaries = rawInnings
            ?.cast<Map<String, dynamic>>()
            .map(MatchInningsSummary.fromJson)
            .toList() ??
        [];

    return MatchData(
      matchNo: json['MatchNo'] as int? ?? 0,
      team1Name: _cleanText(json['Team1Name'] as String? ?? 'Team 1'),
      team2Name: _cleanText(json['Team2Name'] as String? ?? 'Team 2'),
      date: _formatBackendDate(json['Dated'] as String?),
      groundName: _cleanText(json['GroundName'] as String? ?? 'TBA Ground'),
      format: _cleanText(json['Format'] as String? ?? 'T20'),
      tournament: _cleanText(json['Tournament'] as String? ?? 'Cricket Tournament'),
      resultDetail: resultDetail,
      team1: json['Team1'] as int? ?? 0,
      team2: json['Team2'] as int? ?? 0,
      status: status,
      manOfMatchName: json['ManOfMatchName'] != null ? _cleanText(json['ManOfMatchName'] as String) : null,
      cityName: json['CityName'] != null ? _cleanText(json['CityName'] as String) : null,
      countryName: json['CountryName'] != null ? _cleanText(json['CountryName'] as String) : null,
      season: json['Season'] as String?,
      inningsSummaries: inningsSummaries,
    );
  }
}

class FOWDetail {
  const FOWDetail({
    required this.wicket,
    required this.overs,
    required this.score,
    required this.batsmanName,
  });

  final int wicket;
  final String overs;
  final int score;
  final String batsmanName;

  factory FOWDetail.fromJson(Map<String, dynamic> json) => FOWDetail(
        wicket: json['Wicket'] as int? ?? 0,
        overs: '${json['Overs'] ?? '0'}',
        score: json['Score'] as int? ?? 0,
        batsmanName: _cleanText(json['BatsmanName'] as String? ?? 'Batter'),
      );
}

class InningsData {
  const InningsData({
    required this.matchNo,
    required this.innings,
    required this.score,
    required this.overs,
    required this.wickets,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.battingDetail,
    required this.bowlingDetail,
    this.byes = 0,
    this.legByes = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.fow = const [],
  });

  final int matchNo;
  final int innings;
  final int score;
  final String overs;
  final int wickets;
  final String battingTeamName;
  final String bowlingTeamName;
  final List<BattingDetail> battingDetail;
  final List<BowlingDetail> bowlingDetail;
  final int byes;
  final int legByes;
  final int wides;
  final int noBalls;
  final List<FOWDetail> fow;

  factory InningsData.fromJson(Map<String, dynamic> json) => InningsData(
        matchNo: json['MatchNo'] as int? ?? 0,
        innings: json['Innings'] as int? ?? 1,
        score: json['Score'] as int? ?? 0,
        overs: '${json['Overs'] ?? '0'}',
        wickets: json['Wickets'] as int? ?? 0,
        battingTeamName: _cleanText(json['BattingTeamName'] as String? ?? 'Team'),
        bowlingTeamName: _cleanText(json['BowlingTeamName'] as String? ?? 'Team'),
        battingDetail: (json['BattingDetail'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(BattingDetail.fromJson)
                .toList() ??
            [],
        bowlingDetail: (json['BowlingDetail'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(BowlingDetail.fromJson)
                .toList() ??
            [],
        byes: json['Byes'] as int? ?? 0,
        legByes: json['LByes'] as int? ?? 0,
        wides: json['Wides'] as int? ?? 0,
        noBalls: json['NoBalls'] as int? ?? 0,
        fow: (json['FOW'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(FOWDetail.fromJson)
                .toList() ??
            [],
      );
}

class BattingDetail {
  const BattingDetail({
    required this.batsmanName,
    required this.runs,
    required this.ballsFaced,
    required this.fours,
    required this.sixes,
    required this.notOut,
    required this.howOut,
    required this.bowlerName,
    this.outDetail,
  });

  final String batsmanName;
  final int runs;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final int notOut;
  final String howOut;
  final String? bowlerName;
  final String? outDetail;

  factory BattingDetail.fromJson(Map<String, dynamic> json) => BattingDetail(
        batsmanName: _cleanText(json['BatsmanName'] as String? ?? 'Unknown'),
        runs: json['Runs'] as int? ?? 0,
        ballsFaced: json['BallsFaced'] as int? ?? 0,
        fours: json['Fours'] as int? ?? 0,
        sixes: json['Sixes'] as int? ?? 0,
        notOut: json['NotOut'] as int? ?? 0,
        howOut: json['HowOut'] as String? ?? 'Not Out',
        bowlerName: json['BowlerName'] != null ? _cleanText(json['BowlerName'] as String) : null,
        outDetail: json['OutDetail'] != null ? _cleanText(json['OutDetail'] as String) : null,
      );
}

class BowlingDetail {
  const BowlingDetail({
    required this.bowlerName,
    required this.overs,
    required this.maiden,
    required this.runs,
    required this.wickets,
    required this.wides,
    required this.noBalls,
  });

  final String bowlerName;
  final String overs;
  final int maiden;
  final int runs;
  final int wickets;
  final int wides;
  final int noBalls;

  factory BowlingDetail.fromJson(Map<String, dynamic> json) => BowlingDetail(
        bowlerName: _cleanText(json['BowlerName'] as String? ?? 'Unknown'),
        overs: '${json['Overs'] ?? '0'}',
        maiden: json['Maiden'] as int? ?? 0,
        runs: json['Runs'] as int? ?? 0,
        wickets: json['Wickets'] as int? ?? 0,
        wides: json['Wides'] as int? ?? 0,
        noBalls: json['NoBalls'] as int? ?? 0,
      );
}



const realArticles = <ArticleData>[
  ArticleData(
    id: 'pak-women-sri-lanka-2026',
    category: 'PAKISTAN WOMEN',
    title: 'Pakistan women squads announced for Sri Lanka series',
    summary: 'Pakistan named 15-player ODI and T20I squads for six white-ball matches in Hambantota.',
    image: 'assets/images/pakistan_women.png',
    date: '18 July 2026',
    readTime: '4 min read',
    source: 'Pakistan Cricket Board / ICC',
    body: [
      'Pakistan’s Women’s National Selection Committee has announced 15-member squads for the ODI and T20I series against Sri Lanka in Hambantota.',
      'The tour begins with three ODIs on 23, 25 and 28 July. Three T20Is follow on 31 July, 2 August and 4 August, with every match staged at the Mahinda Rajapaksa International Cricket Stadium.',
      'The ODI leg forms part of the ICC Women’s Championship 2025–29. Pakistan entered the tour second in the standings with eight points from six matches, making the series an important step in their qualification campaign.'
    ],
  ),
  ArticleData(
    id: 'babar-discipline-fitness-2026',
    category: 'PLAYER NEWS',
    title: 'Babar Azam returns focused on discipline, fitness and performance',
    summary: 'Pakistan’s Test captain says preparation and consistency will guide the team’s next assignments.',
    image: 'assets/images/babar_batting.png',
    date: '6 July 2026',
    readTime: '5 min read',
    source: 'Pakistan Cricket Board',
    body: [
      'Babar Azam has placed discipline, fitness and performance at the centre of his plans after taking charge of Pakistan’s Test side again.',
      'The batter said preparation for upcoming assignments must be built around clear roles and consistent standards. His return follows a productive Pakistan Super League campaign in which he led Peshawar Zalmi to the title and finished as the competition’s leading run-scorer.',
      'Pakistan will look to turn that renewed confidence into stronger results in the current World Test Championship cycle.'
    ],
  ),
  ArticleData(
    id: 'u19-sports-psychology-2026',
    category: 'U19 DEVELOPMENT',
    title: 'Sports psychology added to Pakistan U19 development camp',
    summary: 'The PCB introduced structured mental-skills work alongside technical and tactical training in Multan.',
    image: 'assets/images/u19_training.png',
    date: '17 July 2026',
    readTime: '3 min read',
    source: 'Pakistan Cricket Board',
    body: [
      'The Pakistan Cricket Board has introduced a structured sports psychology programme at its U19 Skills Development Camp in Multan.',
      'The programme complements technical coaching with work on concentration, confidence, emotional control and decision-making under pressure.',
      'Coaches are using the camp to prepare young players for the demands of high-performance cricket while building habits that can support long-term development.'
    ],
  ),
  ArticleData(
    id: 'womens-t20-world-cup-2028-host',
    category: 'GLOBAL CRICKET',
    title: 'Pakistan confirmed as host of Women’s T20 World Cup 2028',
    summary: 'The ICC approved the qualification pathway for the 12-team tournament to be hosted by the PCB.',
    image: 'assets/images/cricket_stadium.png',
    date: '1 June 2026',
    readTime: '4 min read',
    source: 'International Cricket Council',
    body: [
      'The ICC Board has endorsed the qualification pathway for the Women’s T20 World Cup 2028, which will be hosted by the Pakistan Cricket Board.',
      'The tournament will feature 12 teams. Ten places will be filled through automatic qualification, including the host nation when required, while two remaining berths will come through a 10-team Global Qualifier.',
      'India’s matches are scheduled to be played at a neutral venue. The decision forms part of a wider package designed to strengthen the global women’s cricket pathway.'
    ],
  ),
];

abstract interface class NewsApi {
  Future<List<ArticleData>> getArticles({String? category, int limit = 10, int start = 0});
  Future<ArticleData> getArticle(String id);
}

class MockNewsApi implements NewsApi {
  const MockNewsApi({this.latency = const Duration(milliseconds: 450)});
  final Duration latency;

  @override
  Future<List<ArticleData>> getArticles({String? category, int limit = 10, int start = 0}) async {
    await Future<void>.delayed(latency);
    final response = <String, dynamic>{
      'success': true,
      'data': [for (final article in realArticles) article.toJson()],
      'meta': {'page': 1, 'per_page': realArticles.length, 'total': realArticles.length},
    };
    final items = (response['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ArticleData.fromJson)
        .where((article) => category == null || article.category == category)
        .toList();
    return items;
  }

  @override
  Future<ArticleData> getArticle(String id) async {
    await Future<void>.delayed(latency);
    final match = realArticles.where((article) => article.id == id);
    if (match.isEmpty) throw const NewsApiException(404, 'Article not found');
    return ArticleData.fromJson(match.first.toJson());
  }
}

class KricketNewsApi implements NewsApi {
  const KricketNewsApi({http.Client? client}) : _client = client;

  static const _baseUri = 'https://kricket.pk/backend/api';
  final http.Client? _client;

  @override
  Future<List<ArticleData>> getArticles({String? category, int limit = 10, int start = 0}) async {
    final uri = Uri.parse('$_baseUri/gettoparticles').replace(queryParameters: {'Limit': '$limit', 'Start': '$start'});
    final client = _client ?? http.Client();
    try {
      final response = await client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw NewsApiException(response.statusCode, 'Unable to load articles');
      final payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (payload['status'] != true) throw const NewsApiException(502, 'Kricket API returned an unsuccessful response');
      final received = payload['received_data'] as Map<String, dynamic>?;
      final articles = (received?['articles'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ArticleData.fromBackendJson)
          .where((article) => category == null || article.category == category)
          .toList();
      return articles;
    } on NewsApiException {
      rethrow;
    } catch (_) {
      throw const NewsApiException(503, 'Kricket articles service is unavailable');
    } finally {
      if (_client == null) client.close();
    }
  }

  @override
  Future<ArticleData> getArticle(String id) async {
    // Try different parameter formats the backend might accept
    final possibleUris = [
      Uri.parse('$_baseUri/getarticlebyid').replace(queryParameters: {'id': id}),
      Uri.parse('$_baseUri/getarticlebyid').replace(queryParameters: {'Id': id}),
      Uri.parse('$_baseUri/getarticlebyid').replace(queryParameters: {'ArticleId': id}),
    ];
    
    final client = _client ?? http.Client();
    try {
      for (var uri in possibleUris) {
        print('DEBUG: Trying URI: $uri');
        final response = await client.get(uri).timeout(const Duration(seconds: 15));
        print('DEBUG: Response status: ${response.statusCode}');
        print('DEBUG: Full response body: ${response.body}');
        
        if (response.statusCode != 200) continue;
        
        final payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        print('DEBUG: Payload status: ${payload['status']}');
        
        if (payload['status'] != true) continue;
        
        final receivedList = payload['received_data'] as List<dynamic>?;
        print('DEBUG: Received list length: ${receivedList?.length}');
        
        if (receivedList != null && receivedList.isNotEmpty) {
          final received = receivedList.first as Map<String, dynamic>;
          print('DEBUG: Successfully loaded article from: $uri');
          return ArticleData.fromBackendJson(received);
        }
      }
      
      // If none of the parameter formats worked, throw error
      print('DEBUG: Article not found with any parameter format');
      throw const NewsApiException(404, 'Article not found');
    } on NewsApiException {
      rethrow;
    } catch (e, st) {
      print('DEBUG: Error fetching article: $e');
      print('DEBUG: Stack trace: $st');
      throw const NewsApiException(503, 'Kricket article service is unavailable');
    } finally {
      if (_client == null) client.close();
    }
  }
}

class FallbackNewsApi implements NewsApi {
  const FallbackNewsApi(this.primary, this.fallback);
  final NewsApi primary;
  final NewsApi fallback;

  @override
  Future<List<ArticleData>> getArticles({String? category, int limit = 10, int start = 0}) async {
    try {
      return await primary.getArticles(category: category, limit: limit, start: start);
    } on NewsApiException {
      return fallback.getArticles(category: category, limit: limit, start: start);
    }
  }

  @override
  Future<ArticleData> getArticle(String id) async {
    try {
      return await primary.getArticle(id);
    } on NewsApiException {
      return fallback.getArticle(id);
    }
  }
}

class NewsApiException implements Exception {
  const NewsApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'NewsApiException($statusCode): $message';
}

class PaginationData {
  const PaginationData({
    this.currentPage = 1,
    this.perPage = 10,
    this.totalItems = 0,
    this.totalPages = 1,
  });

  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;

  factory PaginationData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PaginationData();
    return PaginationData(
      currentPage: json['current_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      totalItems: json['total_items'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }
}

class MatchesResponse {
  const MatchesResponse({
    required this.matches,
    required this.pagination,
  });

  final List<MatchData> matches;
  final PaginationData pagination;
}

class MatchesApi {
  static const _baseUri = 'https://kricket.pk/backend/api';

  Future<MatchesResponse> getFixtures({int limit = 10, int page = 1}) async {
    // ignore: avoid_print
    print('[DEBUG MatchesApi] Fetching fixtures from: $_baseUri/fixtures?Limit=$limit&Page=$page');
    try {
      final uri = Uri.parse('$_baseUri/fixtures').replace(
        queryParameters: {'Limit': '$limit', 'Page': '$page'},
      );
      final response = await http.Client().get(uri).timeout(const Duration(seconds: 10));
      // ignore: avoid_print
      print('[DEBUG MatchesApi] Fixtures response HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (payload['status'] == true && payload['received_data'] != null) {
          final matches = (payload['received_data']['matches'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .map(MatchData.fromJson)
                  .toList() ??
              [];
          final pagination = PaginationData.fromJson(payload['received_data']['pagination'] as Map<String, dynamic>?);
          if (matches.isNotEmpty) {
            // ignore: avoid_print
            print('[DEBUG MatchesApi] SUCCESS: Fetched ${matches.length} fixtures (Page ${pagination.currentPage} of ${pagination.totalPages}) from live network API.');
            return MatchesResponse(matches: matches, pagination: pagination);
          }
        }
      }
      // ignore: avoid_print
      print('[DEBUG MatchesApi] WARNING: Live API returned status ${response.statusCode} or empty list. Using fallback fixtures dataset for Page $page.');
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] ERROR fetching live fixtures: $e. Falling back to offline static fixtures dataset for Page $page.');
    }

    return _parseMatchesResponseFromRawJson(_getFallbackFixturesJsonForPage(page), requestedPage: page);
  }

  Future<MatchesResponse> getResults({int limit = 10, int page = 1}) async {
    // ignore: avoid_print
    print('[DEBUG MatchesApi] Fetching results from: $_baseUri/results?Limit=$limit&Page=$page');
    try {
      final uri = Uri.parse('$_baseUri/results').replace(
        queryParameters: {'Limit': '$limit', 'Page': '$page'},
      );
      final response = await http.Client().get(uri).timeout(const Duration(seconds: 10));
      // ignore: avoid_print
      print('[DEBUG MatchesApi] Results response HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (payload['status'] == true && payload['received_data'] != null) {
          final matches = (payload['received_data']['matches'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .map(MatchData.fromJson)
                  .toList() ??
              [];
          final pagination = PaginationData.fromJson(payload['received_data']['pagination'] as Map<String, dynamic>?);
          if (matches.isNotEmpty) {
            // ignore: avoid_print
            print('[DEBUG MatchesApi] SUCCESS: Fetched ${matches.length} results (Page ${pagination.currentPage} of ${pagination.totalPages}) from live network API.');
            return MatchesResponse(matches: matches, pagination: pagination);
          }
        }
      }
      // ignore: avoid_print
      print('[DEBUG MatchesApi] WARNING: Live API returned status ${response.statusCode} or empty list. Using fallback results dataset.');
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] ERROR fetching live results: $e. Falling back to offline static results dataset.');
    }

    return _parseMatchesResponseFromRawJson(_getFallbackResultsJsonForPage(page), requestedPage: page);
  }

  Future<List<InningsData>> getScorecard(int matchNo) async {
    // ignore: avoid_print
    print('[DEBUG MatchesApi] Fetching scorecard for Match #$matchNo from: $_baseUri/scorecard/$matchNo');
    try {
      final uri = Uri.parse('$_baseUri/scorecard/$matchNo');
      final response = await http.Client().get(uri).timeout(const Duration(seconds: 10));
      // ignore: avoid_print
      print('[DEBUG MatchesApi] Scorecard response HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (payload['status'] == true && payload['received_data'] != null) {
          final matchDataList = payload['received_data'] as List<dynamic>?;
          if (matchDataList != null && matchDataList.isNotEmpty) {
            final matchData = matchDataList.first as Map<String, dynamic>;
            final innings = (matchData['Innings'] as List<dynamic>?)
                    ?.cast<Map<String, dynamic>>()
                    .map(InningsData.fromJson)
                    .toList() ??
                [];
            if (innings.isNotEmpty) {
              // ignore: avoid_print
              print('[DEBUG MatchesApi] SUCCESS: Fetched ${innings.length} innings from live scorecard API for Match #$matchNo.');
              return innings;
            }
          }
        }
      }
      // ignore: avoid_print
      print('[DEBUG MatchesApi] WARNING: Live scorecard returned status ${response.statusCode} or empty innings. Using fallback scorecard dataset.');
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] ERROR fetching scorecard for Match #$matchNo: $e. Using fallback scorecard dataset.');
    }

    return _getFallbackScorecard(matchNo);
  }

  MatchesResponse _parseMatchesResponseFromRawJson(String rawJson, {int requestedPage = 1}) {
    try {
      final payload = jsonDecode(rawJson) as Map<String, dynamic>;
      final matchesList = (payload['received_data']['matches'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>()
              .map(MatchData.fromJson)
              .toList() ??
          [];
      var pagination = PaginationData.fromJson(payload['received_data']['pagination'] as Map<String, dynamic>?);
      if (pagination.currentPage != requestedPage) {
        pagination = PaginationData(
          currentPage: requestedPage,
          perPage: pagination.perPage,
          totalItems: pagination.totalItems,
          totalPages: pagination.totalPages,
        );
      }
      // ignore: avoid_print
      print('[DEBUG MatchesApi] Parsed ${matchesList.length} matches (Page ${pagination.currentPage} of ${pagination.totalPages}) from fallback JSON dataset.');
      return MatchesResponse(matches: matchesList, pagination: pagination);
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] Failed to parse raw fallback JSON: $e');
      return const MatchesResponse(matches: [], pagination: PaginationData());
    }
  }

  List<InningsData> _getFallbackScorecard(int matchNo) {
    // ignore: avoid_print
    print('[DEBUG MatchesApi] Searching fallback scorecard dataset for Match #$matchNo');
    try {
      final String jsonStr;
      if (matchNo == 9620) {
        jsonStr = _rawScorecard9620Json;
      } else {
        jsonStr = _rawScorecard10019Json;
      }
      final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
      final matchDataList = payload['received_data'] as List<dynamic>?;
      if (matchDataList != null && matchDataList.isNotEmpty) {
        final matchData = matchDataList.first as Map<String, dynamic>;
        final innings = (matchData['Innings'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(InningsData.fromJson)
                .toList() ??
            [];
        // ignore: avoid_print
        print('[DEBUG MatchesApi] Loaded ${innings.length} fallback innings for Match #$matchNo.');
        return innings;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] Error reading fallback scorecard JSON: $e');
    }
    return [];
  }
}

class KricketApp extends StatelessWidget {
  const KricketApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kricket.pk',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: K.bg,
          colorScheme: ColorScheme.fromSeed(seedColor: K.green),
          fontFamily: 'Inter',
        ),
        home: const AppShell(),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int page = 0;
  late final Future<List<ArticleData>> articles;

  @override
  void initState() {
    super.initState();
    articles = const KricketNewsApi().getArticles(limit: 10, start: 0);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: page < 2 ? const KricketBar() : null,
        body: FutureBuilder<List<ArticleData>>(
          future: articles,
          builder: (context, snapshot) {
            if (snapshot.hasError) return ApiErrorView(error: snapshot.error!);
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: K.green));
            return IndexedStack(index: page, children: [HomeScreen(articles: snapshot.data!), NewsScreen(articles: snapshot.data!), const MatchesScreen(), const PlaceholderScreen(), const PlaceholderScreen()]);
          },
        ),
        bottomNavigationBar: KricketNav(index: page, onTap: (i) => setState(() => page = i)),
      );
}

class ApiErrorView extends StatelessWidget {
  const ApiErrorView({super.key, required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, color: K.green, size: 44), const SizedBox(height: 12), const Text('Unable to load news', style: TextStyle(color: K.dark, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: K.body))])));
}

class KricketBar extends StatelessWidget implements PreferredSizeWidget {
  const KricketBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => AppBar(
        toolbarHeight: 64,
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        leading: const Icon(Icons.menu, size: 20),
        titleSpacing: 0,
        title: const Text('Kricket.pk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        actions: const [Icon(Icons.search, size: 20), SizedBox(width: 16), Icon(Icons.notifications_none, size: 21), SizedBox(width: 16)],
      );
}

class KricketNav extends StatelessWidget {
  const KricketNav({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;
  static const items = [(Icons.home, 'Home'), (Icons.newspaper, 'News'), (Icons.sports_cricket, 'Matches'), (Icons.groups, 'Players'), (Icons.person_outline, 'Profile')];
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 72,
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFBFC9BF))), boxShadow: [BoxShadow(color: Color(0x14004D2C), blurRadius: 10, offset: Offset(0, -4))]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (var i = 0; i < items.length; i++) InkWell(onTap: () => onTap(i), borderRadius: BorderRadius.circular(12), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: EdgeInsets.symmetric(horizontal: i == index ? 16 : 9, vertical: 5), decoration: BoxDecoration(color: i == index ? K.lime : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(items[i].$1, size: 20, color: i == index ? K.limeText : K.body), const SizedBox(height: 2), Text(items[i].$2, style: TextStyle(fontSize: 11, color: i == index ? K.limeText : K.body))])))]),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.articles});
  final List<ArticleData> articles;

  @override
  Widget build(BuildContext context) {
    final topStory = articles.first;
    final newsItems = articles.take(3).toList();
    final trending = (articles.length > 3 ? articles.skip(3) : articles.skip(1)).take(4).toList();

    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 16, bottom: 32 + safeBottom + 72),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Welcome to Kricket.pk', style: TextStyle(color: K.dark, fontSize: 24, height: 1.33, fontWeight: FontWeight.w700, letterSpacing: -.6)), Text('Stay updated with the latest cricket news.', style: TextStyle(color: K.body, fontSize: 16, height: 1.5))])),
        const SizedBox(height: 24),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: K.green, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x14004D2C), blurRadius: 10, offset: Offset(0, 4))]), child: Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LIVE - PAK VS AUS', style: TextStyle(color: Color(0xFF7BBD93), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .6)), SizedBox(height: 4), Text.rich(TextSpan(children: [TextSpan(text: 'PAK 245/4 ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)), TextSpan(text: '(42.3 ov)', style: TextStyle(fontSize: 12, color: Color(0x997BBD93)))]), style: TextStyle(color: Color(0xFF7BBD93)))])), FilledButton(style: FilledButton.styleFrom(backgroundColor: K.lime, foregroundColor: K.limeText, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)), onPressed: () {}, child: const Text('VIEW SCORE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))]))),
           // top story metadata moved into the top story card
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: GestureDetector(onTap: () => openArticle(context, topStory, articles), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(color: Colors.white, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [NetImage(topStory.image, height: 191, width: double.infinity), Positioned(left: 12, top: 12, child: Container(color: const Color(0xFFDC3545), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), child: const Text('TOP STORY', style: TextStyle(color: Colors.white, fontSize: 10))))]), Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(topStory.title, style: const TextStyle(color: K.dark, fontSize: 24, height: 1.25, fontWeight: FontWeight.w600)), const SizedBox(height: 8), Text(topStory.summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: K.body, fontSize: 16, height: 1.5)), const SizedBox(height: 12), const Text('READ MORE', style: TextStyle(color: K.limeText, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2))]))]))))),
        const SizedBox(height: 24),
        const QuickActions(),
        const SectionTitle(title: 'Cricket News', action: 'SEE ALL'),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [for (var i = 0; i < newsItems.length; i++) ...[NewsRow(article: newsItems[i], articles: articles), if (i != newsItems.length - 1) const SizedBox(height: 16)]])),
        const SectionTitle(title: 'Trending Stories', action: ''),
        SizedBox(height: 214, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24), itemBuilder: (context, index) => TrendCard(article: trending[index], articles: articles), separatorBuilder: (_, __) => const SizedBox(width: 16), itemCount: trending.length))
      ]),
    );
  }
}
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});
  @override
  Widget build(BuildContext context) { const data = [(Icons.newspaper, 'Cricket News'),(Icons.sports_cricket, 'Latest\nMatches'),(Icons.scoreboard, 'Live Scores'),(Icons.groups, 'Trending\nPlayers')]; return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [for (var i=0;i<data.length;i++) SizedBox(width: 76, child: Column(children: [Container(width: 56,height:56,decoration: BoxDecoration(color:i==0?K.lime:const Color(0xFFE8E8E8),shape:BoxShape.circle),child:Icon(data[i].$1,size:20,color:K.dark)),const SizedBox(height:8),Text(data[i].$2,textAlign:TextAlign.center,style:const TextStyle(fontSize:11,height:1.27,color:K.ink))]))])); }
}

class SectionTitle extends StatelessWidget { const SectionTitle({super.key,required this.title,required this.action}); final String title,action; @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(24,24,24,16),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(title,style:const TextStyle(color:K.dark,fontSize:20,fontWeight:FontWeight.w600)),Text(action,style:const TextStyle(color:K.limeText,fontSize:12,fontWeight:FontWeight.w700))])); }
class NetImage extends StatelessWidget { const NetImage(this.url,{super.key,this.height,this.width,this.fit=BoxFit.cover}); final String url; final double? height,width; final BoxFit fit; @override Widget build(BuildContext context)=>url.startsWith('assets/')?Image.asset(url,height:height,width:width,fit:fit,errorBuilder:(_,__,___)=>_fallback()):Image.network(url,height:height,width:width,fit:fit,errorBuilder:(_,__,___)=>_fallback()); Widget _fallback()=>Container(height:height,width:width,color:const Color(0xFFE4EAE5),child:const Icon(Icons.sports_cricket,color:K.green,size:42)); }
class NewsRow extends StatelessWidget { const NewsRow({super.key,required this.article,required this.articles}); final ArticleData article; final List<ArticleData> articles; @override Widget build(BuildContext context)=>InkWell(onTap:()=>openArticle(context,article,articles),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(8),child:NetImage(article.image,width:96,height:96)),const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(article.category,style:const TextStyle(color:K.limeText,fontSize:10,fontWeight:FontWeight.w700,letterSpacing:.6)),const SizedBox(height:4),Text(article.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:K.ink,fontSize:16,height:1.35,fontWeight:FontWeight.w700)),const SizedBox(height:4),Text('${article.date} • ${article.readTime}',style:const TextStyle(color:K.body,fontSize:11))]))])); }
class TrendCard extends StatelessWidget { const TrendCard({super.key,required this.article,required this.articles}); final ArticleData article; final List<ArticleData> articles; @override Widget build(BuildContext context)=>InkWell(onTap:()=>openArticle(context,article,articles),borderRadius:BorderRadius.circular(12),child:Container(width:256,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),boxShadow:const [BoxShadow(color:Color(0x10000000),blurRadius:3)]),clipBehavior:Clip.antiAlias,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[NetImage(article.image,width:256,height:130),Padding(padding:const EdgeInsets.symmetric(horizontal:12, vertical:10),child:Text(article.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:K.ink,fontSize:16,height:1.35,fontWeight:FontWeight.w700))) ]))); }

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key, required this.articles});
  final List<ArticleData> articles;
  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(padding: EdgeInsets.only(bottom: 32 + safeBottom + 72), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(height:58,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),children:[chip('All',true),chip('Pakistan'),chip('International'),chip('Domestic'),chip('PSL')])),
    Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:GestureDetector(onTap:()=>openArticle(context,articles[0],articles),child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Stack(children:[NetImage(articles[0].image,width:double.infinity,height:202),Container(height:202,decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xD9001C10)]))),Positioned(left:18,right:18,bottom:18,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(articles[0].title,style:const TextStyle(color:Colors.white,fontSize:23,height:1.15,fontWeight:FontWeight.w700),maxLines:2,overflow:TextOverflow.ellipsis),const SizedBox(height:8),Text(articles[0].summary,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:13))]))])))),
    const SectionTitle(title:'Latest News',action:'VIEW ALL ›'),
    for(var article in articles) NewsListCard(article:article, articles: articles),
    const SectionTitle(title:'Trending Stories',action:''),
    SizedBox(height:150,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),children:[for (final article in articles.skip(1)) ...[RealTrendWide(article: article, articles: articles), const SizedBox(width: 12)]]))
  ]));
  }
  static Widget chip(String t,[bool active=false])=>Container(margin:const EdgeInsets.only(right:8),padding:const EdgeInsets.symmetric(horizontal:22),alignment:Alignment.center,decoration:BoxDecoration(color:active?K.lime:const Color(0xFFF0F1F0),border:active?null:Border.all(color:const Color(0xFFCBD0CB)),borderRadius:BorderRadius.circular(22)),child:Text(t,style:TextStyle(color:active?K.limeText:K.body,fontSize:12,fontWeight:FontWeight.w600)));
}
class NewsListCard extends StatelessWidget { const NewsListCard({super.key,required this.article,required this.articles}); final ArticleData article; final List<ArticleData> articles; @override Widget build(BuildContext context)=>InkWell(onTap:()=>openArticle(context,article,articles),child:Container(margin:const EdgeInsets.fromLTRB(16,0,16,16),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),boxShadow:const [BoxShadow(color:Color(0x10000000),blurRadius:7,offset:Offset(0,3))]),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(8),child:NetImage(article.image,width:88,height:88)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(article.category,style:const TextStyle(color:K.green,fontSize:10,letterSpacing:1)),const SizedBox(height:5),Text(article.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:K.ink,fontSize:15,height:1.25,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text('${article.date} • ${article.readTime}',style:const TextStyle(color:K.body,fontSize:10))])),const Icon(Icons.arrow_forward,color:K.green)]))); }
class TrendWide extends StatelessWidget { const TrendWide({super.key,required this.image,required this.title}); final String image,title; @override Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(14),child:Stack(children:[NetImage(image,width:255,height:150),Container(width:255,height:150,decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xCC001C10)]))),Positioned(left:12,bottom:12,child:Text(title,style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w700))) ])); }

void openArticle(BuildContext context, ArticleData article, List<ArticleData> articles) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => FigmaArticleScreen(article: article, articles: articles)));
}

class RealTrendWide extends StatelessWidget {
  const RealTrendWide({super.key, required this.article, required this.articles});
  final ArticleData article;
  final List<ArticleData> articles;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => openArticle(context, article, articles),
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(children: [
            NetImage(article.image, width: 255, height: 150),
            Container(width: 255, height: 150, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xDD001C10)]))),
            Positioned(left: 12, right: 12, bottom: 12, child: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
          ]),
        ),
      );
}

class FigmaArticleScreen extends StatefulWidget {
  const FigmaArticleScreen({super.key, required this.article, required this.articles});
  final ArticleData article;
  final List<ArticleData> articles;

  @override
  State<FigmaArticleScreen> createState() => _FigmaArticleScreenState();
}

class _FigmaArticleScreenState extends State<FigmaArticleScreen> {
  late final Future<ArticleData> fullArticle;

  @override
  void initState() {
    super.initState();
    fullArticle = const KricketNewsApi().getArticle(widget.article.id);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        toolbarHeight: 64,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: const Color(0x2200341C),
        backgroundColor: Colors.white.withValues(alpha: .97),
        surfaceTintColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back, size: 20), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: const Text('Kricket.pk', style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -.4)),
        actions: const [Icon(Icons.bookmark_border, size: 20), SizedBox(width: 8), Icon(Icons.share_outlined, size: 20), SizedBox(width: 16)],
      ),
      body: FutureBuilder<ArticleData>(
        future: fullArticle,
        builder: (context, snapshot) {
          // Use full article if loaded, otherwise fall back to preview
          final ArticleData article;
          if (snapshot.hasData) {
            article = snapshot.data!;
          } else if (snapshot.hasError) {
            // If full article fails to load, use preview as fallback
            print('DEBUG: Failed to load full article, using preview. Error: ${snapshot.error}');
            article = widget.article;
          } else {
            // Show loading state with preview
            return const Center(child: CircularProgressIndicator(color: K.green));
          }
          
          final related = widget.articles.where((item) => item.id != article.id).take(3).toList();
          
          return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(25, 40, 25, 56 + safeBottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7), decoration: BoxDecoration(color: K.lime.withValues(alpha: .22), border: Border.all(color: K.lime.withValues(alpha: .55)), borderRadius: BorderRadius.circular(999)), child: Text(article.category, style: const TextStyle(color: K.limeText, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
            const Row(children: [Icon(Icons.bookmark_border, size: 19, color: K.dark), SizedBox(width: 18), Icon(Icons.share_outlined, size: 19, color: K.dark)]),
          ]),
          const SizedBox(height: 23),
          Text(article.title, style: const TextStyle(color: K.dark, fontSize: 36, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -.9)),
          const SizedBox(height: 40),
          const SizedBox(height: 40),
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x1A00341C), blurRadius: 28, offset: Offset(0, 16))]), clipBehavior: Clip.antiAlias, child: NetImage(article.image, width: double.infinity, height: 320)),
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.only(top: 16), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x80E2E2E2)))), child: const Text('Editorial cricket image • Kricket.pk', textAlign: TextAlign.center, style: TextStyle(color: K.body, fontSize: 13, height: 1.38, fontStyle: FontStyle.italic))),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E2E2)), bottom: BorderSide(color: Color(0xFFE2E2E2)))),
            child: Row(children: [
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFFE6F0E9), child: Icon(Icons.newspaper, color: K.green)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.source, style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('${article.date}  •  ${article.readTime}', style: const TextStyle(color: K.body, fontSize: 13, fontWeight: FontWeight.w500))])),
            ]),
          ),
          const SizedBox(height: 40),
          for (var i = 0; i < article.body.length; i++) ...[
            Text(article.body[i], style: const TextStyle(color: K.ink, fontSize: 18, height: 1.8)),
            const SizedBox(height: 23),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(33),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E2E2)), borderRadius: BorderRadius.circular(32), boxShadow: const [BoxShadow(color: Color(0x1400341C), blurRadius: 25, offset: Offset(0, 20))]),
            child: Column(children: [
              const Text('VERIFIED CRICKET REPORT', style: TextStyle(color: Color(0x8000341C), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.2)),
              const SizedBox(height: 12),
              const Icon(Icons.verified, color: K.green, size: 56),
              const SizedBox(height: 8),
              Text(article.date, textAlign: TextAlign.center, style: const TextStyle(color: K.ink, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('Reporting checked against ${article.source}.', textAlign: TextAlign.center, style: const TextStyle(color: K.body, fontSize: 14, height: 1.6)),
              const SizedBox(height: 20),
              Container(width: 48, height: 4, decoration: BoxDecoration(color: K.lime, borderRadius: BorderRadius.circular(99))),
            ]),
          ),
          const SizedBox(height: 48),
          Container(padding: const EdgeInsets.fromLTRB(32, 42, 24, 16), child: Stack(clipBehavior: Clip.none, children: [
            const Positioned(left: -32, top: -42, child: Text('“', style: TextStyle(color: Color(0x1A00341C), fontSize: 80, fontFamily: 'serif'))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.title, style: const TextStyle(color: K.dark, fontSize: 24, height: 1.25, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, letterSpacing: -.6)), const SizedBox(height: 28), Text('— ${article.source.toUpperCase()}', style: const TextStyle(color: K.body, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2))]),
          ])),
          const SizedBox(height: 42),
          Wrap(spacing: 10, runSpacing: 10, children: [for (final tag in _tagsFor(article)) Container(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9), decoration: BoxDecoration(color: const Color(0xFFF3F3F4), border: Border.all(color: const Color(0xFFE2E2E2)), borderRadius: BorderRadius.circular(12)), child: Text(tag, style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 48),
          const Divider(color: Color(0xFFE2E2E2), thickness: 2),
          const SizedBox(height: 44),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Continue Reading', style: TextStyle(color: K.dark, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.55)), SizedBox(width: 48, child: Divider(color: Color(0x5500341C), thickness: 2))]),
          const SizedBox(height: 32),
          for (final item in related) ...[_RelatedArticleCard(article: item, articles: widget.articles), const SizedBox(height: 32)],
          const SizedBox(height: 8),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 36),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: K.dark, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 64), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8, shadowColor: K.green.withValues(alpha: .35)),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to News', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
            ]),
          );
        },
      ),
    );
  }

  List<String> _tagsFor(ArticleData value) => ['#PakistanCricket', '#${value.category.replaceAll(' ', '')}', '#News'];
}

class _RelatedArticleCard extends StatelessWidget {
  const _RelatedArticleCard({required this.article, required this.articles});
  final ArticleData article;
  final List<ArticleData> articles;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FigmaArticleScreen(article: article, articles: articles))),
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 15, offset: Offset(0, 8))]), clipBehavior: Clip.antiAlias, child: NetImage(article.image, width: double.infinity, height: 191)),
          const SizedBox(height: 15),
          Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: K.ink, fontSize: 18, height: 1.38, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${article.readTime}  •  ${article.category}', style: const TextStyle(color: K.limeText, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}

class RealArticleScreen extends StatelessWidget {
  const RealArticleScreen({super.key, required this.article});
  final ArticleData article;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titleSpacing: 0,
          title: const Text('Kricket.pk', style: TextStyle(color: K.green, fontSize: 16, fontWeight: FontWeight.w700)),
          actions: const [Icon(Icons.bookmark_border), Icon(Icons.share_outlined), SizedBox(width: 8)],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 24, 25, 48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: K.lime, borderRadius: BorderRadius.circular(18)), child: Text(article.category, style: const TextStyle(color: K.limeText, fontSize: 11, fontWeight: FontWeight.w700))),
            const SizedBox(height: 22),
            Text(article.title, style: const TextStyle(color: K.dark, fontSize: 32, height: 1.08, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.only(left: 18), decoration: const BoxDecoration(border: Border(left: BorderSide(color: K.lime, width: 3))), child: Text(article.summary, style: const TextStyle(color: K.body, fontSize: 16, height: 1.5))),
            const SizedBox(height: 22),
            Row(children: [
              const CircleAvatar(radius: 22, backgroundColor: Color(0xFFE4EAE5), child: Icon(Icons.newspaper, color: K.green)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.source, style: const TextStyle(fontWeight: FontWeight.w700)), Text('${article.date}  •  ${article.readTime}', style: const TextStyle(color: K.body, fontSize: 11))])),
            ]),
            const SizedBox(height: 28),
            ClipRRect(borderRadius: BorderRadius.circular(12), child: NetImage(article.image, width: double.infinity, height: 320)),
            const SizedBox(height: 12),
            Center(child: Text('Photo used for editorial illustration • ${article.source}', textAlign: TextAlign.center, style: const TextStyle(color: K.body, fontSize: 10, fontStyle: FontStyle.italic))),
            const SizedBox(height: 30),
            for (var i = 0; i < article.body.length; i++) ...[
              if (i == 1) const ArticleHeading('What you need to know'),
              ArticleText(article.body[i]),
              const SizedBox(height: 18),
            ],
            Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFF6F8F5), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFDDE7DD))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('SOURCE', style: TextStyle(color: K.green, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)), const SizedBox(height: 8), Text(article.source, style: const TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 6), const Text('This article summary uses verified reporting current to July 2026.', style: TextStyle(color: K.body, fontSize: 12, height: 1.5))])),
            const SizedBox(height: 28),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: K.dark, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => Navigator.pop(context), child: const Text('Back to News')),
          ]),
        ),
      );
}

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key});
  static const hero='https://www.figma.com/api/mcp/asset/f2d12722-30ba-49cc-9fc5-5545ac12abd6';
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:Colors.white,appBar:AppBar(backgroundColor:Colors.white,titleSpacing:0,title:const Text('Kricket.pk',style:TextStyle(color:K.green,fontSize:16,fontWeight:FontWeight.w700)),actions:const [Icon(Icons.bookmark_border),Icon(Icons.share_outlined),SizedBox(width:8)]),body:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(25,24,25,40),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),decoration:BoxDecoration(color:K.lime,borderRadius:BorderRadius.circular(18)),child:const Text('ICC WORLD CUP',style:TextStyle(color:K.limeText,fontSize:11,fontWeight:FontWeight.w700))),const SizedBox(height:22),
    const Text("The Rise of Babar Azam: A Statistical Deep Dive into Pakistan's Batting Pillar",style:TextStyle(color:K.dark,fontSize:32,height:1.08,fontWeight:FontWeight.w800)),const SizedBox(height:20),
    Container(padding:const EdgeInsets.only(left:18),decoration:const BoxDecoration(border:Border(left:BorderSide(color:K.lime,width:3))),child:const Text("How the captain's technique and consistency are rewriting the record books across all formats.",style:TextStyle(color:K.body,fontSize:16,height:1.5))),const SizedBox(height:22),
    const Row(children:[CircleAvatar(radius:22,backgroundColor:Color(0xFFE4EAE5),child:Icon(Icons.person,color:K.green)),SizedBox(width:12),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Zahid Ahmed',style:TextStyle(fontWeight:FontWeight.w700)),Text('Oct 24, 2023  •  8 min read',style:TextStyle(color:K.body,fontSize:11))])]),const SizedBox(height:28),
    ClipRRect(borderRadius:BorderRadius.circular(12),child:NetImage(hero,width:double.infinity,height:320)),const SizedBox(height:12),const Center(child:Text("Babar Azam's signature cover drive has become a symbol of his technical mastery.",textAlign:TextAlign.center,style:TextStyle(color:K.body,fontSize:10,fontStyle:FontStyle.italic))),const SizedBox(height:30),
    const ArticleText('In the pantheon of modern cricketing greats, few names resonate with the same rhythmic elegance as Babar Azam. While contemporaries might rely on brute force or unorthodox geometry, Babar operates with the precision of a master watchmaker.\n\nHis journey from the streets of Lahore to the summit of the ICC rankings is not just a tale of talent, but a testament to a technical blueprint that seems almost bulletproof.'),
    const ArticleHeading('Consistency is King'),
    const ArticleText('The hallmark of Babar’s batting is his incredible ability to find the gaps with surgical precision. Unlike the frantic pace of modern T20I batting, Babar brings a sense of calm to the crease. Analysts point to his weight transfer as the secret sauce; whether facing a 150kph thunderbolt or a subtle drifter, his head remains still, eyes level, and his bat flows through a perfect arc.'),const SizedBox(height:28),
    Container(width:double.infinity,padding:const EdgeInsets.all(28),decoration:BoxDecoration(color:const Color(0xFFF6F8F5),borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFDDE7DD))),child:const Column(children:[Text('AVERAGE IN WINNING CAUSES',style:TextStyle(color:K.green,fontSize:11,fontWeight:FontWeight.w700,letterSpacing:1)),SizedBox(height:12),Text('64.28',style:TextStyle(color:K.dark,fontSize:46,fontWeight:FontWeight.w800)),Text('Highest among active top-order batsmen',textAlign:TextAlign.center,style:TextStyle(color:K.body,fontSize:12))])),const SizedBox(height:28),
    Container(padding:const EdgeInsets.all(24),decoration:const BoxDecoration(border:Border(left:BorderSide(color:K.lime,width:4))),child:const Text('Leadership in Pakistan cricket is often a poisoned chalice, yet Babar has worn it with a quiet stoicism.\n\n— THE EDITORIAL BOARD',style:TextStyle(color:K.dark,fontSize:20,height:1.45,fontWeight:FontWeight.w700,fontStyle:FontStyle.italic))),const ArticleHeading('Continue Reading'),
    const SizedBox(height:24),
    FilledButton(style:FilledButton.styleFrom(backgroundColor:K.dark,minimumSize:const Size(double.infinity,56),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),onPressed:()=>Navigator.pop(context),child:const Text('‹  Share Story'))
  ])));
}
class ArticleHeading extends StatelessWidget { const ArticleHeading(this.text,{super.key}); final String text; @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:30,bottom:16),child:Text(text,style:const TextStyle(color:K.dark,fontSize:27,fontWeight:FontWeight.w800))); }
class ArticleText extends StatelessWidget { const ArticleText(this.text,{super.key}); final String text; @override Widget build(BuildContext context)=>Text(text,style:const TextStyle(color:K.ink,fontSize:16,height:1.75)); }

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;
  
  // Active page trackers
  int _fixturesPage = 1;
  int _resultsPage = 1;

  late Future<MatchesResponse> _fixturesFuture;
  late Future<MatchesResponse> _resultsFuture;

  final List<String> _categories = ['All', 'International', 'Domestic', 'PSL', 'Women'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // ignore: avoid_print
    print('[DEBUG MatchesScreen] Initializing MatchesScreen state...');
    _loadData();
  }

  void _loadData() {
    final api = MatchesApi();
    _fixturesFuture = api.getFixtures(limit: 10, page: _fixturesPage);
    _resultsFuture = api.getResults(limit: 10, page: _resultsPage);
  }

  void _changeFixturesPage(int page) {
    setState(() {
      _fixturesPage = page;
      // ignore: avoid_print
      print('[DEBUG MatchesScreen] Navigating Fixtures to Page $page');
      _fixturesFuture = MatchesApi().getFixtures(limit: 10, page: page);
    });
  }

  void _changeResultsPage(int page) {
    setState(() {
      _resultsPage = page;
      // ignore: avoid_print
      print('[DEBUG MatchesScreen] Navigating Results to Page $page');
      _resultsFuture = MatchesApi().getResults(limit: 10, page: page);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: K.dark,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text('Matches', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5)),
        actions: const [
          Icon(Icons.search, size: 20, color: Colors.white),
          SizedBox(width: 14),
          Icon(Icons.notifications_none, size: 20, color: Colors.white),
          SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: K.dark,
              unselectedLabelColor: K.body,
              indicatorColor: K.lime,
              indicatorWeight: 3.5,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Fixtures'),
                Tab(text: 'Results'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category Filters Row
          Container(
            height: 48,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final active = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? K.dark : const Color(0xFFF0F2F0),
                      borderRadius: BorderRadius.circular(20),
                      border: active ? null : Border.all(color: const Color(0xFFDCDFDB)),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: active ? K.lime : K.body,
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8ECE8)),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Fixtures Tab View
                _MatchesListView(
                  responseFuture: _fixturesFuture,
                  selectedCategory: _categories[_selectedCategoryIndex],
                  currentPage: _fixturesPage,
                  onPageChanged: _changeFixturesPage,
                ),
                // Results Tab View
                _MatchesListView(
                  responseFuture: _resultsFuture,
                  selectedCategory: _categories[_selectedCategoryIndex],
                  currentPage: _resultsPage,
                  onPageChanged: _changeResultsPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchesListView extends StatefulWidget {
  const _MatchesListView({
    required this.responseFuture,
    required this.selectedCategory,
    required this.currentPage,
    required this.onPageChanged,
  });

  final Future<MatchesResponse> responseFuture;
  final String selectedCategory;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  State<_MatchesListView> createState() => _MatchesListViewState();
}

class _MatchesListViewState extends State<_MatchesListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _MatchesListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MatchesResponse>(
        future: widget.responseFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // ignore: avoid_print
            print('[DEBUG _MatchesListView] Error loading matches: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, color: K.green, size: 48),
                    const SizedBox(height: 12),
                    const Text('Unable to load matches', style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: K.body, fontSize: 12)),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: K.green));
          }

          final response = snapshot.data!;
          var matches = response.matches;
          final pagination = response.pagination;

          if (widget.selectedCategory != 'All') {
            final catLower = widget.selectedCategory.toLowerCase();
            matches = matches.where((m) =>
                m.tournament.toLowerCase().contains(catLower) ||
                m.format.toLowerCase().contains(catLower) ||
                (catLower == 'psl' && m.tournament.toLowerCase().contains('premier league')) ||
                (catLower == 'women' && m.tournament.toLowerCase().contains('women'))
            ).toList();
          }

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                if (matches.isNotEmpty) ...[
                  for (final match in matches)
                    MatchCard(
                      match: match,
                      onTap: () {
                        // ignore: avoid_print
                        print('[DEBUG MatchesScreen] User tapped Match #${match.matchNo}: ${match.team1Name} vs ${match.team2Name}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MatchDetailScreen(matchNo: match.matchNo, initialMatch: match),
                          ),
                        );
                      },
                    ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_cricket, color: Color(0xFFB0BEB3), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No ${widget.selectedCategory} matches on Page ${widget.currentPage}',
                          style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        const Text('Use the pagination bar below to switch pages or select "All".', textAlign: TextAlign.center, style: TextStyle(color: K.body, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                
                // Dynamic Pagination Control Bar
                _buildPaginationBar(context, pagination),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );

  Widget _buildPaginationBar(BuildContext context, PaginationData pagination) {
    final cur = widget.currentPage;
    final total = pagination.totalPages > 0 ? pagination.totalPages : 1;

    final pages = <int>[];
    int start = (cur - 2).clamp(1, total);
    int end = (start + 4).clamp(1, total);
    if (end - start < 4 && start > 1) {
      start = (end - 4).clamp(1, total);
    }
    for (int p = start; p <= end; p++) {
      pages.add(p);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          // First Button
          _pageBtn(
            label: 'First',
            disabled: cur <= 1,
            onTap: () {
              widget.onPageChanged(1);
              _scrollToTop();
            },
          ),
          // Previous Button
          _pageBtn(
            label: 'Previous',
            disabled: cur <= 1,
            onTap: () {
              widget.onPageChanged(cur - 1);
              _scrollToTop();
            },
          ),

          // Numeric Page Buttons (1, 2, 3, 4, 5...)
          for (final p in pages)
            GestureDetector(
              onTap: () {
                widget.onPageChanged(p);
                _scrollToTop();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p == cur ? K.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: p == cur ? null : Border.all(color: const Color(0xFFDCDFDB)),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      color: p == cur ? Colors.white : K.dark,
                      fontSize: 13,
                      fontWeight: p == cur ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Next Button
          _pageBtn(
            label: 'Next',
            disabled: cur >= total,
            onTap: () {
              widget.onPageChanged(cur + 1);
              _scrollToTop();
            },
          ),
          // Last Button
          _pageBtn(
            label: 'Last',
            disabled: cur >= total,
            onTap: () {
              widget.onPageChanged(total);
              _scrollToTop();
            },
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({required String label, required bool disabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF2F4F2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: disabled ? const Color(0xFFE2E4E2) : K.green),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled ? const Color(0xFFA0AAA2) : K.green,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  final MatchData match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    MatchInningsSummary? team1Innings;
    MatchInningsSummary? team2Innings;

    for (final inn in match.inningsSummaries) {
      if (inn.battingTeamName.toLowerCase() == match.team1Name.toLowerCase()) {
        team1Innings = inn;
      } else if (inn.battingTeamName.toLowerCase() == match.team2Name.toLowerCase()) {
        team2Innings = inn;
      }
    }
    if (team1Innings == null && match.inningsSummaries.isNotEmpty) {
      team1Innings = match.inningsSummaries.first;
      if (match.inningsSummaries.length > 1) {
        team2Innings = match.inningsSummaries[1];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE8)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C00341C), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row: Tournament Tag & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.tournament.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: K.body, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .5),
                    ),
                  ),
                  _statusBadge(match.status, match.date),
                ],
              ),
              const SizedBox(height: 14),

              // Teams Row (Team 1 vs Team 2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Team 1
                  Expanded(
                    child: Column(
                      children: [
                        _TeamAvatar(name: match.team1Name),
                        const SizedBox(height: 8),
                        Text(match.team1Name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: K.ink, fontSize: 14, fontWeight: FontWeight.w700)),
                        if (team1Innings != null) ...[
                          const SizedBox(height: 4),
                          Text('${team1Innings.score}/${team1Innings.wickets}', style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w900)),
                          Text('${team1Innings.overs} ov', style: const TextStyle(color: K.body, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),

                  // VS Divider Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF2F4F2), borderRadius: BorderRadius.circular(12)),
                    child: const Text('VS', style: TextStyle(color: K.body, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),

                  // Team 2
                  Expanded(
                    child: Column(
                      children: [
                        _TeamAvatar(name: match.team2Name),
                        const SizedBox(height: 8),
                        Text(match.team2Name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: K.ink, fontSize: 14, fontWeight: FontWeight.w700)),
                        if (team2Innings != null) ...[
                          const SizedBox(height: 4),
                          Text('${team2Innings.score}/${team2Innings.wickets}', style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w900)),
                          Text('${team2Innings.overs} ov', style: const TextStyle(color: K.body, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Result Detail Box if available
              if (match.resultDetail != null && match.resultDetail!.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F8F4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD4E6D8)),
                  ),
                  child: Text(
                    match.resultDetail!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: K.limeText, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),

              const Divider(height: 1, color: Color(0xFFE8ECE8)),
              const SizedBox(height: 10),

              // Footer: Ground Venue & Match Centre Link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: K.body),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${match.groundName} • ${match.date}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: K.body, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Row(
                    children: [
                      Text('Match Centre', style: TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward, size: 14, color: K.dark),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, String date) {
    if (status == 'L') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFFFEBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFC2C2))),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 3, backgroundColor: Colors.red),
            SizedBox(width: 4),
            Text('LIVE', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    } else if (status == 'P') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFE6F3EC), borderRadius: BorderRadius.circular(12)),
        child: const Text('COMPLETED', style: TextStyle(color: K.limeText, fontSize: 9, fontWeight: FontWeight.w800)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(12)),
        child: const Text('UPCOMING', style: TextStyle(color: K.body, fontSize: 9, fontWeight: FontWeight.w700)),
      );
    }
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.name, this.size = 36});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final bg = _getBgColor(name);
    final fontSize = (size * 0.32).clamp(9.0, 14.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  String _getInitials(String str) {
    final parts = str.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return str.length >= 3 ? str.substring(0, 3).toUpperCase() : str.toUpperCase();
    }
    return parts.take(3).map((e) => e[0]).join().toUpperCase();
  }

  Color _getBgColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('india')) return const Color(0xFF1B4997);
    if (lower.contains('england')) return const Color(0xFFCF142B);
    if (lower.contains('balochistan')) return const Color(0xFF006633);
    if (lower.contains('khyber')) return const Color(0xFF004D40);
    if (lower.contains('punjab')) return const Color(0xFFD81B60);
    if (lower.contains('sindh')) return const Color(0xFF00838F);
    if (lower.contains('northern')) return const Color(0xFF6A1B9A);
    if (lower.contains('gujarat')) return const Color(0xFF1A237E);
    if (lower.contains('bengaluru') || lower.contains('rcb')) return const Color(0xFFC62828);
    if (lower.contains('rajasthan')) return const Color(0xFFAD1457);
    if (lower.contains('sunrisers') || lower.contains('hyderabad')) return const Color(0xFFEF6C00);
    return K.green;
  }
}

class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({
    super.key,
    required this.matchNo,
    this.initialMatch,
  });

  final int matchNo;
  final MatchData? initialMatch;

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late final Future<List<InningsData>> scorecardFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // ignore: avoid_print
    print('[DEBUG MatchDetailScreen] Opened MatchDetailScreen for Match #${widget.matchNo}');
    scorecardFuture = MatchesApi().getScorecard(widget.matchNo);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: K.bg,
        appBar: AppBar(
          toolbarHeight: 56,
          backgroundColor: K.dark,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.initialMatch != null
                ? '${widget.initialMatch!.team1Name} vs ${widget.initialMatch!.team2Name}'
                : 'Match #${widget.matchNo}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: const [
            Icon(Icons.share_outlined, size: 20),
            SizedBox(width: 16),
          ],
        ),
        body: FutureBuilder<List<InningsData>>(
          future: scorecardFuture,
          builder: (context, snapshot) {
            final inningsList = snapshot.data ?? [];
            final match = widget.initialMatch;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _buildHeroHeader(match, inningsList),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: K.dark,
                      unselectedLabelColor: K.body,
                      indicatorColor: K.lime,
                      indicatorWeight: 3.5,
                      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      tabs: const [
                        Tab(text: 'Summary'),
                        Tab(text: 'Scorecard'),
                        Tab(text: 'Commentary'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(match, inningsList),
                  _ScorecardTabWidget(inningsList: inningsList, match: match),
                  _buildCommentaryTab(match, inningsList),
                ],
              ),
            );
          },
        ),
      );

  Widget _buildHeroHeader(MatchData? match, List<InningsData> inningsList) {
    final team1Name = match?.team1Name ?? (inningsList.isNotEmpty ? inningsList[0].battingTeamName : 'Team 1');
    final team2Name = match?.team2Name ?? (inningsList.length > 1 ? inningsList[1].battingTeamName : 'Team 2');

    InningsData? team1Innings;
    InningsData? team2Innings;
    for (final inn in inningsList) {
      if (inn.battingTeamName.toLowerCase() == team1Name.toLowerCase()) {
        team1Innings = inn;
      } else if (inn.battingTeamName.toLowerCase() == team2Name.toLowerCase()) {
        team2Innings = inn;
      }
    }
    if (team1Innings == null && inningsList.isNotEmpty) team1Innings = inningsList[0];
    if (team2Innings == null && inningsList.length > 1) team2Innings = inningsList[1];

    final resultDetail = match?.resultDetail;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [K.dark, Color(0xFF002413)],
        ),
      ),
      child: Column(
        children: [
          Text(
            '${(match?.team1Name ?? 'PAK').toUpperCase()} VS ${(match?.team2Name ?? 'AUS').toUpperCase()} — ${match?.format.toUpperCase() ?? '1ST ODI'}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: K.lime, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8),
          ),
          const SizedBox(height: 16),

          // Main Scoreboard Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Team 1
              Expanded(
                child: Column(
                  children: [
                    _TeamAvatar(name: team1Name),
                    const SizedBox(height: 8),
                    Text(team1Name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (team1Innings != null) ...[
                      Text('${team1Innings.score}/${team1Innings.wickets}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text('OVERS: ${team1Innings.overs}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                    ] else
                      const Text('-', style: TextStyle(color: Colors.white70, fontSize: 20)),
                  ],
                ),
              ),

              // Team 2
              Expanded(
                child: Column(
                  children: [
                    _TeamAvatar(name: team2Name),
                    const SizedBox(height: 8),
                    Text(team2Name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (team2Innings != null) ...[
                      Text('${team2Innings.score}/${team2Innings.wickets}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text('OVERS: ${team2Innings.overs}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                    ] else
                      const Text('-', style: TextStyle(color: Colors.white70, fontSize: 20)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                match?.groundName ?? 'Gaddafi Stadium, Lahore',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          if (resultDetail != null && resultDetail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              resultDetail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: K.lime, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryTab(MatchData? match, List<InningsData> inningsList) {
    final bool isScheduledFixture = match?.status == 'S' || ((match?.resultDetail == null || match!.resultDetail!.isEmpty) && inningsList.isEmpty && (match?.inningsSummaries == null || match!.inningsSummaries.isEmpty));

    // If scheduled fixture, ONLY show Match Overview!
    if (isScheduledFixture) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECE8)),
                boxShadow: const [BoxShadow(color: Color(0x0A00341C), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MATCH OVERVIEW', style: TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .5)),
                  const SizedBox(height: 12),
                  _infoRow('Tournament', match?.tournament ?? 'N/A'),
                  _infoRow('Match No', '#${widget.matchNo}'),
                  _infoRow('Format', match?.format ?? 'T20'),
                  _infoRow('Season', match?.season ?? '2025-26'),
                  _infoRow('Venue Ground', match?.groundName ?? 'TBA'),
                  _infoRow('Date & Time', match?.date ?? 'TBA'),
                  if (match?.cityName != null) _infoRow('City', match!.cityName!),
                  if (match?.countryName != null) _infoRow('Country', match!.countryName!),
                  _infoRow('Official Status', 'Official PCB / ICC Fixture'),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      );
    }

    // Otherwise, construct innings display list for completed/live matches
    final List<InningsData> displayInnings;
    if (inningsList.isNotEmpty) {
      displayInnings = inningsList;
    } else if (match != null && match.inningsSummaries.isNotEmpty) {
      displayInnings = [
        for (final summ in match.inningsSummaries)
          InningsData(
            matchNo: match.matchNo,
            innings: summ.innings,
            score: summ.score,
            overs: summ.overs,
            wickets: summ.wickets,
            battingTeamName: summ.battingTeamName,
            bowlingTeamName: summ.bowlingTeamName,
            battingDetail: const [],
            bowlingDetail: const [],
          )
      ];
    } else {
      displayInnings = const [];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Result Detail Banner
          if (match?.resultDetail != null && match!.resultDetail!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F3EC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC2E4D2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFF0B7337), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MATCH RESULT', style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5)),
                        const SizedBox(height: 2),
                        Text(match.resultDetail!, style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Innings Summary Cards with Top Batters & Bowlers
          if (displayInnings.isNotEmpty) ...[
            const Text('INNINGS BREAKDOWN', style: TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .5)),
            const SizedBox(height: 10),
            for (final inn in displayInnings) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8ECE8)),
                  boxShadow: const [BoxShadow(color: Color(0x0A00341C), blurRadius: 6)],
                ),
                child: Column(
                  children: [
                    // Green Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B7337),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: Row(
                        children: [
                          _TeamAvatar(name: inn.battingTeamName, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${inn.battingTeamName} (Innings ${inn.innings})',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${inn.score}/${inn.wickets}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            ' (${inn.overs} ov)',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),

                    // Top Performers Row (Batters on Left, Bowlers on Right)
                    if (inn.battingDetail.isNotEmpty || inn.bowlingDetail.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top 3 Batters
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final b in (List<BattingDetail>.from(inn.battingDetail)..sort((a, b) => b.runs.compareTo(a.runs))).take(3))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              b.batsmanName,
                                              style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${b.runs} (${b.ballsFaced})',
                                            style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Top 3 Bowlers
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final bw in (List<BowlingDetail>.from(inn.bowlingDetail)..sort((a, b) => b.wickets != a.wickets ? b.wickets.compareTo(a.wickets) : a.runs.compareTo(b.runs))).take(3))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              bw.bowlerName,
                                              style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${bw.wickets}-${bw.runs} (${bw.overs})',
                                            style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('vs ${inn.bowlingTeamName}', style: const TextStyle(color: K.body, fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('Run Rate: ${_calcRR(inn.score, double.tryParse(inn.overs) ?? 0.0)}', style: const TextStyle(color: K.body, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // 3. Player of the Match Card (if in API)
          if (match?.manOfMatchName != null && match!.manOfMatchName!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECE8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFB300), size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PLAYER OF THE MATCH', style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5)),
                      const SizedBox(height: 2),
                      Text(match.manOfMatchName!, style: const TextStyle(color: K.ink, fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Match Information Card from API
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECE8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MATCH OVERVIEW', style: TextStyle(color: K.dark, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .5)),
                const SizedBox(height: 12),
                _infoRow('Tournament', match?.tournament ?? 'N/A'),
                _infoRow('Match No', '#${widget.matchNo}'),
                _infoRow('Format', match?.format ?? 'T20'),
                _infoRow('Season', match?.season ?? '2025-26'),
                _infoRow('Venue Ground', match?.groundName ?? 'TBA'),
                _infoRow('Date & Time', match?.date ?? 'TBA'),
                if (match?.cityName != null) _infoRow('City', match!.cityName!),
                if (match?.countryName != null) _infoRow('Country', match!.countryName!),
                _infoRow('Official Status', 'Official PCB / ICC Match'),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildCommentaryTab(MatchData? match, List<InningsData> inningsList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 64),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.subtitles_off_outlined, color: Color(0xFFB0BEB3), size: 48),
            const SizedBox(height: 14),
            Text(
              'No commentary overs found for Match #${widget.matchNo}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ball-by-ball commentary is updated in real-time during live match broadcasts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: K.body, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _calcRR(int score, double overs) {
    if (overs <= 0) return '0.0';
    return (score / overs).toStringAsFixed(2);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: K.body, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: K.ink, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ScorecardTabWidget extends StatefulWidget {
  const _ScorecardTabWidget({required this.inningsList, required this.match});
  final List<InningsData> inningsList;
  final MatchData? match;

  @override
  State<_ScorecardTabWidget> createState() => _ScorecardTabWidgetState();
}

class _ScorecardTabWidgetState extends State<_ScorecardTabWidget> {
  int _selectedInningsIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isScheduledFixture = widget.match?.status == 'S' || ((widget.match?.resultDetail == null || widget.match!.resultDetail!.isEmpty) && widget.inningsList.isEmpty && (widget.match?.inningsSummaries == null || widget.match!.inningsSummaries.isEmpty));

    if (isScheduledFixture) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_cricket_outlined, color: Color(0xFFB0BEB3), size: 48),
              const SizedBox(height: 12),
              const Text(
                'No Scorecard Available Yet',
                style: TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Scorecard details will be updated once the match begins.',
                textAlign: TextAlign.center,
                style: TextStyle(color: K.body, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final List<InningsData> displayList;
    if (widget.inningsList.isNotEmpty) {
      displayList = widget.inningsList;
    } else if (widget.match != null && widget.match!.inningsSummaries.isNotEmpty) {
      displayList = [
        for (final summ in widget.match!.inningsSummaries)
          InningsData(
            matchNo: widget.match!.matchNo,
            innings: summ.innings,
            score: summ.score,
            overs: summ.overs,
            wickets: summ.wickets,
            battingTeamName: summ.battingTeamName,
            bowlingTeamName: summ.bowlingTeamName,
            battingDetail: const [],
            bowlingDetail: const [],
          )
      ];
    } else {
      displayList = const [];
    }

    if (displayList.isEmpty) {
      return const Center(
        child: Text('No scorecard data available', style: TextStyle(color: K.body, fontSize: 14, fontWeight: FontWeight.w600)),
      );
    }

    final safeIndex = _selectedInningsIndex.clamp(0, displayList.length - 1);
    final activeInnings = displayList[safeIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Innings Selector Pills Row (1st innings, 2nd innings...)
          if (displayList.length > 1) ...[
            Row(
              children: [
                for (int i = 0; i < displayList.length; i++) ...[
                  GestureDetector(
                    onTap: () => setState(() => _selectedInningsIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                      decoration: BoxDecoration(
                        color: i == safeIndex ? const Color(0xFF2C2C2C) : const Color(0xFFF2F4F2),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: i == safeIndex
                            ? const [BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2))]
                            : null,
                      ),
                      child: Text(
                        '${i == 0 ? '1st' : i == 1 ? '2nd' : '${i + 1}th'} innings',
                        style: TextStyle(
                          color: i == safeIndex ? Colors.white : K.dark,
                          fontSize: 13,
                          fontWeight: i == safeIndex ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Selected Innings Scorecard
          InningsCard(innings: activeInnings),
        ],
      ),
    );
  }
}

class InningsCard extends StatelessWidget {
  const InningsCard({super.key, required this.innings});
  final InningsData innings;

  String _calcSR(int runs, int balls) {
    if (balls <= 0) return '0.0';
    return ((runs / balls) * 100).toStringAsFixed(1);
  }

  String _calcEcon(int runs, String oversStr) {
    final ov = double.tryParse(oversStr) ?? 0.0;
    if (ov <= 0) return '0.00';
    final parts = oversStr.split('.');
    double fullOvers = double.tryParse(parts[0]) ?? 0.0;
    if (parts.length > 1) {
      final balls = double.tryParse(parts[1]) ?? 0.0;
      fullOvers += balls / 6.0;
    }
    if (fullOvers <= 0) return '0.00';
    return (runs / fullOvers).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Batting & Extras Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECE8)),
            boxShadow: const [BoxShadow(color: Color(0x0A00341C), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B7337),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    _TeamAvatar(name: innings.battingTeamName, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${innings.battingTeamName} (Innings ${innings.innings})',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${innings.score}/${innings.wickets}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      ' (${innings.overs} ov)',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              // Batting Table Header
              if (innings.battingDetail.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: const Color(0xFFFAFAFA),
                  child: const Row(
                    children: [
                      Expanded(flex: 7, child: Text('BATTER', style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w800))),
                      Expanded(flex: 2, child: Text('R', textAlign: TextAlign.right, style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w800))),
                      Expanded(flex: 2, child: Text('B', textAlign: TextAlign.right, style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w800))),
                      Expanded(flex: 2, child: Text('4s', textAlign: TextAlign.right, style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w800))),
                      Expanded(flex: 2, child: Text('6s', textAlign: TextAlign.right, style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w800))),
                      Expanded(flex: 3, child: Text('SR', textAlign: TextAlign.right, style: TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w800))),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE8ECE8)),

                // Batting Rows
                for (final batter in innings.battingDetail) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                batter.batsmanName,
                                style: TextStyle(
                                  color: K.dark,
                                  fontSize: 12,
                                  fontWeight: batter.notOut == 1 || batter.howOut == 'Not Out' ? FontWeight.w800 : FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                batter.notOut == 1 || batter.howOut == 'Not Out'
                                    ? 'Not Out'
                                    : (batter.outDetail != null && batter.outDetail!.isNotEmpty
                                        ? batter.outDetail!
                                        : batter.howOut),
                                style: const TextStyle(color: K.body, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: Text('${batter.runs}', textAlign: TextAlign.right, style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800))),
                        Expanded(flex: 2, child: Text('${batter.ballsFaced}', textAlign: TextAlign.right, style: const TextStyle(color: K.body, fontSize: 11))),
                        Expanded(flex: 2, child: Text('${batter.fours}', textAlign: TextAlign.right, style: const TextStyle(color: K.body, fontSize: 11))),
                        Expanded(flex: 2, child: Text('${batter.sixes}', textAlign: TextAlign.right, style: const TextStyle(color: K.body, fontSize: 11))),
                        Expanded(flex: 3, child: Text(_calcSR(batter.runs, batter.ballsFaced), textAlign: TextAlign.right, style: const TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F2F0)),
                ],
              ],

              // Separate Extras Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Extras', style: TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(
                      '(b ${innings.byes}, lb ${innings.legByes}, w ${innings.wides}, nb ${innings.noBalls}, p 0)',
                      style: const TextStyle(color: K.body, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE8ECE8)),

              // Total Green Bar Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: const Color(0xFF0B7337),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                    Text(
                      '${innings.score}  ${innings.overs} overs',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),

              // Fall of Wickets Row
              if (innings.fow.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Fall of wickets: ',
                              style: TextStyle(color: K.dark, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            TextSpan(
                              text: innings.fow
                                  .map((f) => '${f.wicket}-${f.score} (${f.batsmanName}, ${f.overs} ov)')
                                  .join(', '),
                              style: const TextStyle(color: K.body, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // 2. Separate Bowling Section with Bowling Country/Team Name Header above it!
        if (innings.bowlingDetail.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              innings.bowlingTeamName.isNotEmpty ? innings.bowlingTeamName : 'Bowling',
              style: const TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECE8)),
              boxShadow: const [BoxShadow(color: Color(0x0A00341C), blurRadius: 8)],
            ),
            child: Column(
              children: [
                // Green BOWLING Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B7337),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 7, child: Text('BOWLING', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                      Expanded(flex: 2, child: Text('O', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                      Expanded(flex: 2, child: Text('M', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                      Expanded(flex: 2, child: Text('R', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                      Expanded(flex: 2, child: Text('W', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                      Expanded(flex: 3, child: Text('ECON', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                    ],
                  ),
                ),
                for (final bowler in innings.bowlingDetail) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: Text(
                            bowler.bowlerName,
                            style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(flex: 2, child: Text(bowler.overs, textAlign: TextAlign.right, style: const TextStyle(color: K.body, fontSize: 11))),
                        Expanded(flex: 2, child: Text('${bowler.maiden}', textAlign: TextAlign.right, style: const TextStyle(color: K.body, fontSize: 11))),
                        Expanded(flex: 2, child: Text('${bowler.runs}', textAlign: TextAlign.right, style: const TextStyle(color: K.body, fontSize: 11))),
                        Expanded(flex: 2, child: Text('${bowler.wickets}', textAlign: TextAlign.right, style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w800))),
                        Expanded(flex: 3, child: Text(_calcEcon(bowler.runs, bowler.overs), textAlign: TextAlign.right, style: const TextStyle(color: K.body, fontSize: 10, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F2F0)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Coming soon', style: TextStyle(color: K.dark, fontSize: 22, fontWeight: FontWeight.w700)),
      );
}

// -----------------------------------------------------------------------------
// RAW FALLBACK DATASETS FROM USER PROMPT
// -----------------------------------------------------------------------------



const String _rawResultsPage1Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":10019,"Season":"2025-26","Dated":"2026-07-19T13:30:00.000Z","GroundName":"Lord's","Team":1,"Club":0,"ManOfMatch":18706,"ManOfMatchName":"Jacob Bethell","Team1":1014,"Team2":1015,"GroundId":325,"TournamentId":195,"RoundId":82,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"England","Type":"Tournament","Format":"One Day","Level":"","Tournament":" India tour of England_ODI 2026","Live":"","Official":"Official","ResultDetail":"England won by 27 runs","CityName":"Bristol","CountryName":"England","Innings":[{"MatchNo":10019,"Innings":1,"Score":387,"Overs":50,"Byes":0,"LByes":9,"Wides":16,"NoBalls":1,"BattingTeam":1015,"BowlingTeam":1014,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-07-19T18:24:09.000Z","BattingTeamName":"England","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10019,"Innings":2,"Score":360,"Overs":50,"Byes":1,"LByes":3,"Wides":6,"NoBalls":0,"BattingTeam":1014,"BowlingTeam":1015,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-07-19T18:24:09.000Z","BattingTeamName":"India","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10018,"Season":"2025-26","Dated":"2026-07-16T13:00:00.000Z","GroundName":"Sophia Gardens","Team":1,"Club":0,"ManOfMatch":19129,"ManOfMatchName":"Joe Root","Team1":1016,"Team2":1017,"GroundId":324,"TournamentId":195,"RoundId":82,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"England","Type":"Tournament","Format":"One Day","Level":"","Tournament":" India tour of England_ODI 2026","Live":"","Official":"Official","ResultDetail":"England won by 4 wickets (with 35 balls remaining)","CityName":"Bristol","CountryName":"England","Innings":[{"MatchNo":10018,"Innings":1,"Score":233,"Overs":44,"Byes":0,"LByes":6,"Wides":8,"NoBalls":0,"BattingTeam":1016,"BowlingTeam":1017,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-07-17T18:15:56.000Z","BattingTeamName":"India","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10018,"Innings":2,"Score":235,"Overs":44.1,"Byes":0,"LByes":4,"Wides":12,"NoBalls":4,"BattingTeam":1017,"BowlingTeam":1016,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-07-17T18:15:56.000Z","BattingTeamName":"England","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10017,"Season":"2025-26","Dated":"2026-07-14T11:00:00.000Z","GroundName":"Edgbaston","Team":1,"Club":0,"ManOfMatch":18664,"ManOfMatchName":"Axar Patel","Team1":1016,"Team2":1017,"GroundId":323,"TournamentId":195,"RoundId":82,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"England","Type":"Tournament","Format":"One Day","Level":"","Tournament":" India tour of England_ODI 2026","Live":"","Official":"Official","ResultDetail":"India won by 6 wickets (with 28 balls remaining)","CityName":"Bristol","CountryName":"England","Innings":[{"MatchNo":10017,"Innings":1,"Score":258,"Overs":47.5,"Byes":12,"LByes":2,"Wides":4,"NoBalls":0,"BattingTeam":1017,"BowlingTeam":1016,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-07-16T16:26:03.000Z","BattingTeamName":"England","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10017,"Innings":2,"Score":262,"Overs":45.2,"Byes":0,"LByes":0,"Wides":20,"NoBalls":1,"BattingTeam":1016,"BowlingTeam":1017,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-07-16T16:26:03.000Z","BattingTeamName":"India","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10016,"Season":"2025-26","Dated":"2026-07-11T06:30:00.000Z","GroundName":"The Rose Bowl","Team":1,"Club":0,"ManOfMatch":18707,"ManOfMatchName":"Jos Buttler","Team1":1014,"Team2":1015,"GroundId":322,"TournamentId":194,"RoundId":81,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"England","Type":"Tournament","Format":"T20","Level":"","Tournament":"India tour of England 2026","Live":"","Official":"Official","ResultDetail":"England won by 56 runs","CityName":"Southampton","CountryName":"England","Innings":[{"MatchNo":10016,"Innings":1,"Score":257,"Overs":20,"Byes":0,"LByes":2,"Wides":15,"NoBalls":1,"BattingTeam":1015,"BowlingTeam":1014,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-07-14T17:23:21.000Z","BattingTeamName":"England","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10016,"Innings":2,"Score":201,"Overs":20,"Byes":0,"LByes":1,"Wides":3,"NoBalls":1,"BattingTeam":1014,"BowlingTeam":1015,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-07-14T17:23:21.000Z","BattingTeamName":"India","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10015,"Season":"2025-26","Dated":"2026-07-09T09:30:00.000Z","GroundName":"County Ground","Team":1,"Club":0,"ManOfMatch":18596,"ManOfMatchName":" Harry Brook ","Team1":1014,"Team2":1015,"GroundId":321,"TournamentId":194,"RoundId":81,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"England","Type":"Tournament","Format":"T20","Level":"","Tournament":"India tour of England 2026","Live":"","Official":"Official","ResultDetail":"England won by 9 wickets (with 37 balls remaining)","CityName":"Bristol","CountryName":"England","Innings":[{"MatchNo":10015,"Innings":1,"Score":158,"Overs":20,"Byes":0,"LByes":1,"Wides":3,"NoBalls":0,"BattingTeam":1014,"BowlingTeam":1015,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-07-14T17:22:57.000Z","BattingTeamName":"India","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10015,"Innings":2,"Score":159,"Overs":13.5,"Byes":0,"LByes":6,"Wides":5,"NoBalls":2,"BattingTeam":1015,"BowlingTeam":1014,"Wickets":1,"UpdateBy":1,"UpdateTime":"2026-07-14T17:22:57.000Z","BattingTeamName":"England","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10014,"Season":"2025-26","Dated":"2026-07-07T09:30:00.000Z","GroundName":"Trent Bridge","Team":1,"Club":0,"ManOfMatch":13890,"ManOfMatchName":"Jofra Archer","Team1":1014,"Team2":1015,"GroundId":320,"TournamentId":194,"RoundId":81,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"England","Type":"Tournament","Format":"T20","Level":"","Tournament":"India tour of England 2026","Live":"","Official":"Official","ResultDetail":"England won by 125 runs","CityName":"Nottingham","CountryName":"England","Innings":[{"MatchNo":10014,"Innings":1,"Score":201,"Overs":20,"Byes":0,"LByes":1,"Wides":5,"NoBalls":0,"BattingTeam":1015,"BowlingTeam":1015,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-07-08T15:53:27.000Z","BattingTeamName":"England","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10014,"Innings":2,"Score":76,"Overs":11.4,"Byes":0,"LByes":0,"Wides":0,"NoBalls":0,"BattingTeam":1014,"BowlingTeam":1015,"Wickets":10,"UpdateBy":19,"UpdateTime":"2026-07-08T15:54:08.000Z","BattingTeamName":"India","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10013,"Season":"2025-26","Dated":"2026-07-04T06:30:00.000Z","GroundName":"Old Trafford","Team":1,"Club":0,"ManOfMatch":18706,"ManOfMatchName":"Jacob Bethell","Team1":1014,"Team2":1015,"GroundId":319,"TournamentId":194,"RoundId":81,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"England","Type":"Tournament","Format":"T20","Level":"","Tournament":"India tour of England 2026","Live":"","Official":"Official","ResultDetail":"England won by 4 wickets (with 6 balls remaining)","CityName":"Manchester","CountryName":"England","Innings":[{"MatchNo":10013,"Innings":1,"Score":190,"Overs":20,"Byes":0,"LByes":1,"Wides":9,"NoBalls":0,"BattingTeam":1014,"BowlingTeam":1015,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-07-08T15:52:36.000Z","BattingTeamName":"India","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10013,"Innings":2,"Score":191,"Overs":19,"Byes":0,"LByes":4,"Wides":4,"NoBalls":3,"BattingTeam":1015,"BowlingTeam":1014,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-07-08T15:52:36.000Z","BattingTeamName":"England","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9959,"Season":"2025-26","Dated":"2026-05-31T19:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":18995,"ManOfMatchName":"Virat Kohli","Team1":1004,"Team2":1007,"GroundId":300,"TournamentId":193,"RoundId":80,"GroupId":null,"TournamentGroup":null,"Team1Name":"Royal Challengers Bengaluru","Team2Name":"Gujarat Titans","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"Live","Official":"Official","ResultDetail":"RCB won by 5 wickets (with 12 balls remaining)","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9959,"Innings":1,"Score":155,"Overs":20,"Byes":0,"LByes":1,"Wides":4,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1004,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-31T14:23:16.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":18785,"ballsInCurrentOver":0,"CurrentNonStrikePlayerId":18884,"CurrentBowlerPlayerId":19066},{"MatchNo":9959,"Innings":2,"Score":161,"Overs":18,"Byes":0,"LByes":1,"Wides":1,"NoBalls":0,"BattingTeam":1004,"BowlingTeam":1007,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-31T16:17:46.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":18995,"ballsInCurrentOver":0,"CurrentNonStrikePlayerId":18991,"CurrentBowlerPlayerId":19071}]},{"MatchNo":10011,"Season":"2025-26","Dated":"2026-05-29T07:00:00.000Z","GroundName":"Maharaja Yadavindra Singh Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19014,"ManOfMatchName":"Shubman Gill","Team1":1012,"Team2":1007,"GroundId":315,"TournamentId":193,"RoundId":79,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Gujarat Titans","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"GT won by 7 wickets (with 8 balls remaining)","CityName":"New Chandigarh","CountryName":"India","Innings":[{"MatchNo":10011,"Innings":1,"Score":214,"Overs":20,"Byes":0,"LByes":0,"Wides":6,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1007,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T20:02:47.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10011,"Innings":2,"Score":219,"Overs":18.4,"Byes":4,"LByes":0,"Wides":11,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1012,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-06-10T20:02:47.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10010,"Season":"2025-26","Dated":"2026-05-27T19:00:00.000Z","GroundName":"Maharaja Yadavindra Singh Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19031,"ManOfMatchName":"Vaibhav Sooryavanshi","Team1":1012,"Team2":1013,"GroundId":315,"TournamentId":193,"RoundId":78,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Sunrisers Hyderabad","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RR won by 47 runs","CityName":"New Chandigarh","CountryName":"India","Innings":[{"MatchNo":10010,"Innings":1,"Score":243,"Overs":20,"Byes":2,"LByes":0,"Wides":3,"NoBalls":1,"BattingTeam":1012,"BowlingTeam":1013,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T20:00:24.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10010,"Innings":2,"Score":196,"Overs":19.2,"Byes":0,"LByes":0,"Wides":15,"NoBalls":1,"BattingTeam":1013,"BowlingTeam":1012,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T20:00:24.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":1,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage2Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":10009,"Season":"2025-26","Dated":"2026-05-26T19:00:00.000Z","GroundName":"Himachal Pradesh Cricket Association Stadium","Team":1,"Club":0,"ManOfMatch":18993,"ManOfMatchName":"Rajat Patidar","Team1":1004,"Team2":1007,"GroundId":317,"TournamentId":193,"RoundId":77,"GroupId":0,"TournamentGroup":null,"Team1Name":"Royal Challengers Bengaluru","Team2Name":"Gujarat Titans","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RCB won by 92 runs","CityName":"Dharamsala","CountryName":"India","Innings":[{"MatchNo":10009,"Innings":1,"Score":254,"Overs":20,"Byes":1,"LByes":1,"Wides":3,"NoBalls":2,"BattingTeam":1004,"BowlingTeam":1007,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T20:00:11.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10009,"Innings":2,"Score":162,"Overs":19.3,"Byes":0,"LByes":1,"Wides":6,"NoBalls":1,"BattingTeam":1007,"BowlingTeam":1004,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T20:00:11.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10008,"Season":"2025-26","Dated":"2026-05-24T19:00:00.000Z","GroundName":"Eden Gardens","Team":1,"Club":0,"ManOfMatch":18863,"ManOfMatchName":"Kuldeep Yadav","Team1":1006,"Team2":1008,"GroundId":304,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Delhi Capitals","Team2Name":"Kolkata Knight Riders","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"DC won by 40 runs","CityName":"Kolkata","CountryName":"India","Innings":[{"MatchNo":10008,"Innings":1,"Score":203,"Overs":20,"Byes":1,"LByes":2,"Wides":8,"NoBalls":1,"BattingTeam":1006,"BowlingTeam":1008,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T19:56:30.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10008,"Innings":2,"Score":163,"Overs":18.4,"Byes":0,"LByes":0,"Wides":5,"NoBalls":0,"BattingTeam":1008,"BowlingTeam":1006,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T19:56:30.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10007,"Season":"2025-26","Dated":"2026-05-24T15:00:00.000Z","GroundName":"Wankhede Stadium","Team":1,"Club":0,"ManOfMatch":13890,"ManOfMatchName":"Jofra Archer","Team1":1012,"Team2":1010,"GroundId":303,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Mumbai Indians","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RR won by 30 runs","CityName":"Mumbai","CountryName":"India","Innings":[{"MatchNo":10007,"Innings":1,"Score":205,"Overs":20,"Byes":0,"LByes":1,"Wides":6,"NoBalls":2,"BattingTeam":1012,"BowlingTeam":1010,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T19:56:17.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10007,"Innings":2,"Score":175,"Overs":20,"Byes":0,"LByes":0,"Wides":4,"NoBalls":1,"BattingTeam":1010,"BowlingTeam":1012,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-06-10T19:56:17.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10006,"Season":"2025-26","Dated":"2026-05-23T19:00:00.000Z","GroundName":"Bharat Ratna Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19019,"ManOfMatchName":"Shreyas Iyer","Team1":1009,"Team2":1011,"GroundId":314,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lucknow Super Giants","Team2Name":"Punjab Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"PBKS won by 7 wickets (with 12 balls remaining)","CityName":"Lucknow","CountryName":"India","Innings":[{"MatchNo":10006,"Innings":1,"Score":196,"Overs":20,"Byes":0,"LByes":2,"Wides":8,"NoBalls":0,"BattingTeam":1009,"BowlingTeam":1011,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T19:53:58.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10006,"Innings":2,"Score":200,"Overs":18,"Byes":0,"LByes":0,"Wides":3,"NoBalls":0,"BattingTeam":1011,"BowlingTeam":1009,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-06-10T19:53:58.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10005,"Season":"2025-26","Dated":"2026-05-22T19:00:00.000Z","GroundName":"Rajiv Gandhi International Stadium","Team":1,"Club":0,"ManOfMatch":18666,"ManOfMatchName":"Ishan Kishan","Team1":1013,"Team2":1004,"GroundId":312,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sunrisers Hyderabad","Team2Name":"Royal Challengers Bengaluru","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"SRH won by 55 runs","CityName":"Hyderabad","CountryName":"India","Innings":[{"MatchNo":10005,"Innings":1,"Score":255,"Overs":20,"Byes":0,"LByes":0,"Wides":14,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1004,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:53:51.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10005,"Innings":2,"Score":200,"Overs":20,"Byes":0,"LByes":2,"Wides":5,"NoBalls":1,"BattingTeam":1004,"BowlingTeam":1013,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:53:51.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10004,"Season":"2025-26","Dated":"2026-05-21T19:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":18667,"ManOfMatchName":"Mohammed Siraj","Team1":1007,"Team2":1005,"GroundId":300,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Gujarat Titans","Team2Name":"Chennai Super Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"GT won by 89 runs","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":10004,"Innings":1,"Score":229,"Overs":20,"Byes":0,"LByes":3,"Wides":13,"NoBalls":1,"BattingTeam":1007,"BowlingTeam":1005,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:48:54.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10004,"Innings":2,"Score":140,"Overs":13.4,"Byes":0,"LByes":0,"Wides":4,"NoBalls":0,"BattingTeam":1005,"BowlingTeam":1007,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T19:48:54.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10003,"Season":"2025-26","Dated":"2026-05-20T19:00:00.000Z","GroundName":"Eden Gardens","Team":1,"Club":0,"ManOfMatch":19110,"ManOfMatchName":"Manish Pandey","Team1":1010,"Team2":1008,"GroundId":304,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Mumbai Indians","Team2Name":"Kolkata Knight Riders","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"KKR won by 4 wickets (with 7 balls remaining)","CityName":"Kolkata","CountryName":"India","Innings":[{"MatchNo":10003,"Innings":1,"Score":147,"Overs":20,"Byes":4,"LByes":2,"Wides":3,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1008,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T19:48:48.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10003,"Innings":2,"Score":148,"Overs":18.5,"Byes":0,"LByes":1,"Wides":4,"NoBalls":1,"BattingTeam":1008,"BowlingTeam":1010,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T19:48:48.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10002,"Season":"2025-26","Dated":"2026-05-19T19:00:00.000Z","GroundName":"Sawai Mansingh Stadium","Team":1,"Club":0,"ManOfMatch":19031,"ManOfMatchName":"Vaibhav Sooryavanshi","Team1":1009,"Team2":1012,"GroundId":313,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lucknow Super Giants","Team2Name":"Rajasthan Royals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RR won by 7 wickets (with 5 balls remaining)","CityName":"Jaipur","CountryName":"India","Innings":[{"MatchNo":10002,"Innings":1,"Score":220,"Overs":20,"Byes":0,"LByes":3,"Wides":9,"NoBalls":1,"BattingTeam":1009,"BowlingTeam":1012,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T19:46:29.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10002,"Innings":2,"Score":225,"Overs":19.1,"Byes":0,"LByes":3,"Wides":10,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1009,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-06-10T19:46:29.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10001,"Season":"2025-26","Dated":"2026-05-18T19:00:00.000Z","GroundName":"M. A. Chidambaram Stadium","Team":1,"Club":0,"ManOfMatch":18666,"ManOfMatchName":"Ishan Kishan","Team1":1005,"Team2":1013,"GroundId":301,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Chennai Super Kings","Team2Name":"Sunrisers Hyderabad","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"SRH won by 5 wickets (with 6 balls remaining)","CityName":"Chennai","CountryName":"India","Innings":[{"MatchNo":10001,"Innings":1,"Score":180,"Overs":20,"Byes":0,"LByes":0,"Wides":8,"NoBalls":1,"BattingTeam":1005,"BowlingTeam":1013,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-06-10T19:46:24.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10001,"Innings":2,"Score":181,"Overs":19,"Byes":0,"LByes":0,"Wides":6,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1005,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T19:46:24.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":10000,"Season":"2025-26","Dated":"2026-05-17T19:00:00.000Z","GroundName":"Arun Jaitley Stadium","Team":1,"Club":0,"ManOfMatch":19097,"ManOfMatchName":"Mitchell Starc","Team1":1012,"Team2":1006,"GroundId":302,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Delhi Capitals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"DC won by 5 wickets (with 4 balls remaining)","CityName":"New Delhi","CountryName":"India","Innings":[{"MatchNo":10000,"Innings":1,"Score":193,"Overs":20,"Byes":0,"LByes":2,"Wides":6,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1006,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T19:44:08.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":10000,"Innings":2,"Score":197,"Overs":19.2,"Byes":1,"LByes":2,"Wides":13,"NoBalls":0,"BattingTeam":1006,"BowlingTeam":1012,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T19:44:08.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":2,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage3Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9999,"Season":"2025-26","Dated":"2026-05-17T15:00:00.000Z","GroundName":"Himachal Pradesh Cricket Association Stadium","Team":1,"Club":0,"ManOfMatch":19062,"ManOfMatchName":"Venkatesh Iyer","Team1":1004,"Team2":1011,"GroundId":317,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Royal Challengers Bengaluru","Team2Name":"Punjab Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RCB won by 23 runs","CityName":"Dharamsala","CountryName":"India","Innings":[{"MatchNo":9999,"Innings":1,"Score":222,"Overs":20,"Byes":1,"LByes":0,"Wides":5,"NoBalls":1,"BattingTeam":1004,"BowlingTeam":1011,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:44:14.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9999,"Innings":2,"Score":199,"Overs":20,"Byes":0,"LByes":4,"Wides":8,"NoBalls":0,"BattingTeam":1011,"BowlingTeam":1004,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T19:44:14.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9998,"Season":"2025-26","Dated":"2026-05-16T19:00:00.000Z","GroundName":"Eden Gardens","Team":1,"Club":0,"ManOfMatch":8206,"ManOfMatchName":"Sunil Narine","Team1":1008,"Team2":1007,"GroundId":304,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Kolkata Knight Riders","Team2Name":"Gujarat Titans","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"KKR won by 29 runs","CityName":"Kolkata","CountryName":"India","Innings":[{"MatchNo":9998,"Innings":1,"Score":247,"Overs":20,"Byes":0,"LByes":1,"Wides":4,"NoBalls":1,"BattingTeam":1008,"BowlingTeam":1007,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-06-10T19:41:01.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9998,"Innings":2,"Score":218,"Overs":20,"Byes":1,"LByes":8,"Wides":11,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1008,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:41:01.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9997,"Season":"2025-26","Dated":"2026-05-15T19:00:00.000Z","GroundName":"Bharat Ratna Cricket Stadium","Team":1,"Club":0,"ManOfMatch":18868,"ManOfMatchName":"Mitchell Marsh","Team1":1005,"Team2":1009,"GroundId":314,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Chennai Super Kings","Team2Name":"Lucknow Super Giants","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"LSG won by 7 wickets (with 20 balls remaining)","CityName":"Lucknow","CountryName":"India","Innings":[{"MatchNo":9997,"Innings":1,"Score":187,"Overs":20,"Byes":0,"LByes":0,"Wides":7,"NoBalls":0,"BattingTeam":1005,"BowlingTeam":1009,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T19:40:54.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9997,"Innings":2,"Score":188,"Overs":16.4,"Byes":1,"LByes":6,"Wides":3,"NoBalls":0,"BattingTeam":1009,"BowlingTeam":1005,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-06-10T19:40:54.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9996,"Season":"2025-26","Dated":"2026-05-14T19:00:00.000Z","GroundName":"Himachal Pradesh Cricket Association Stadium","Team":1,"Club":0,"ManOfMatch":18672,"ManOfMatchName":"Tilak Varma","Team1":1011,"Team2":1010,"GroundId":317,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Punjab Kings","Team2Name":"Mumbai Indians","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"MI won by 6 wickets (with 1 ball remaining)","CityName":"Dharamsala","CountryName":"India","Innings":[{"MatchNo":9996,"Innings":1,"Score":200,"Overs":20,"Byes":5,"LByes":1,"Wides":7,"NoBalls":0,"BattingTeam":1011,"BowlingTeam":1010,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T19:38:08.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9996,"Innings":2,"Score":205,"Overs":19.5,"Byes":0,"LByes":0,"Wides":3,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1011,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:38:08.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9995,"Season":"2025-26","Dated":"2026-05-13T07:00:00.000Z","GroundName":"Shaheed Veer Narayan Singh International Stadium","Team":1,"Club":0,"ManOfMatch":18995,"ManOfMatchName":"Virat Kohli","Team1":1008,"Team2":1004,"GroundId":316,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Kolkata Knight Riders","Team2Name":"Royal Challengers Bengaluru","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RCB won by 6 wickets (with 5 balls remaining)","CityName":"Raipur","CountryName":"India","Innings":[{"MatchNo":9995,"Innings":1,"Score":192,"Overs":20,"Byes":0,"LByes":1,"Wides":2,"NoBalls":0,"BattingTeam":1008,"BowlingTeam":1004,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:38:02.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9995,"Innings":2,"Score":194,"Overs":19.1,"Byes":0,"LByes":4,"Wides":10,"NoBalls":0,"BattingTeam":1004,"BowlingTeam":1008,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:38:02.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9994,"Season":"2025-26","Dated":"2026-05-12T19:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":18785,"ManOfMatchName":"Kagiso Rabada","Team1":1007,"Team2":1013,"GroundId":300,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Gujarat Titans","Team2Name":"Sunrisers Hyderabad","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"GT won by 82 runs","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9994,"Innings":1,"Score":168,"Overs":20,"Byes":0,"LByes":2,"Wides":6,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1013,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T19:35:31.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9994,"Innings":2,"Score":86,"Overs":14.5,"Byes":0,"LByes":1,"Wides":1,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1007,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T19:35:31.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9993,"Season":"2025-26","Dated":"2026-05-11T19:00:00.000Z","GroundName":"Himachal Pradesh Cricket Association Stadium","Team":1,"Club":0,"ManOfMatch":19107,"ManOfMatchName":"Madhav Tiwari","Team1":1011,"Team2":1006,"GroundId":317,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Punjab Kings","Team2Name":"Delhi Capitals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"DC won by 3 wickets (with 6 balls remaining)","CityName":"Dharamsala","CountryName":"India","Innings":[{"MatchNo":9993,"Innings":1,"Score":210,"Overs":20,"Byes":4,"LByes":0,"Wides":11,"NoBalls":2,"BattingTeam":1011,"BowlingTeam":1006,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T19:35:25.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9993,"Innings":2,"Score":216,"Overs":19,"Byes":0,"LByes":0,"Wides":17,"NoBalls":1,"BattingTeam":1006,"BowlingTeam":1011,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-06-10T19:35:25.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9992,"Season":"2025-26","Dated":"2026-05-10T19:00:00.000Z","GroundName":"Shaheed Veer Narayan Singh International Stadium","Team":1,"Club":0,"ManOfMatch":18989,"ManOfMatchName":"Bhuvneshwar Kumar","Team1":1010,"Team2":1004,"GroundId":316,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Mumbai Indians","Team2Name":"Royal Challengers Bengaluru","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RCB won by 2 wickets (with 0 balls remaining)","CityName":"Raipur","CountryName":"India","Innings":[{"MatchNo":9992,"Innings":1,"Score":166,"Overs":20,"Byes":0,"LByes":3,"Wides":3,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1004,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-06-10T19:33:01.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9992,"Innings":2,"Score":167,"Overs":20,"Byes":0,"LByes":3,"Wides":11,"NoBalls":1,"BattingTeam":1004,"BowlingTeam":1010,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T19:33:01.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9991,"Season":"2025-26","Dated":"2026-05-10T15:00:00.000Z","GroundName":"M. A. Chidambaram Stadium","Team":1,"Club":0,"ManOfMatch":18829,"ManOfMatchName":"Jamie Overton","Team1":1009,"Team2":1005,"GroundId":301,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lucknow Super Giants","Team2Name":"Chennai Super Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"CSK won by 5 wickets (with 4 balls remaining)","CityName":"Chennai","CountryName":"India","Innings":[{"MatchNo":9991,"Innings":1,"Score":203,"Overs":20,"Byes":0,"LByes":2,"Wides":5,"NoBalls":1,"BattingTeam":1009,"BowlingTeam":1005,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T19:32:48.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9991,"Innings":2,"Score":208,"Overs":19.2,"Byes":0,"LByes":2,"Wides":9,"NoBalls":0,"BattingTeam":1005,"BowlingTeam":1009,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T19:32:48.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9990,"Season":"2025-26","Dated":"2026-05-09T19:00:00.000Z","GroundName":"Sawai Mansingh Stadium","Team":1,"Club":0,"ManOfMatch":18490,"ManOfMatchName":"Rashid Khan ","Team1":1007,"Team2":1012,"GroundId":313,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Gujarat Titans","Team2Name":"Rajasthan Royals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"GT won by 77 runs","CityName":"Jaipur","CountryName":"India","Innings":[{"MatchNo":9990,"Innings":1,"Score":229,"Overs":20,"Byes":1,"LByes":1,"Wides":16,"NoBalls":1,"BattingTeam":1007,"BowlingTeam":1012,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:30:14.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9990,"Innings":2,"Score":152,"Overs":16.3,"Byes":0,"LByes":1,"Wides":2,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1007,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T19:30:14.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":3,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage4Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9989,"Season":"2025-26","Dated":"2026-05-08T19:00:00.000Z","GroundName":"Arun Jaitley Stadium","Team":1,"Club":0,"ManOfMatch":18694,"ManOfMatchName":"Finn Allen","Team1":1006,"Team2":1008,"GroundId":302,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Delhi Capitals","Team2Name":"Kolkata Knight Riders","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"KKR won by 8 wickets (with 34 balls remaining)","CityName":"New Delhi","CountryName":"India","Innings":[{"MatchNo":9989,"Innings":1,"Score":142,"Overs":20,"Byes":0,"LByes":0,"Wides":2,"NoBalls":0,"BattingTeam":1006,"BowlingTeam":1008,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T19:30:20.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9989,"Innings":2,"Score":147,"Overs":14.2,"Byes":0,"LByes":0,"Wides":0,"NoBalls":0,"BattingTeam":1008,"BowlingTeam":1006,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-06-10T19:30:20.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9988,"Season":"2025-26","Dated":"2026-05-07T19:00:00.000Z","GroundName":"Bharat Ratna Cricket Stadium","Team":1,"Club":0,"ManOfMatch":18868,"ManOfMatchName":"Mitchell Marsh","Team1":1009,"Team2":1004,"GroundId":314,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lucknow Super Giants","Team2Name":"Royal Challengers Bengaluru","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"LSG won by 9 runs (DLS method)","CityName":"Lucknow","CountryName":"India","Innings":[{"MatchNo":9988,"Innings":1,"Score":209,"Overs":19,"Byes":0,"LByes":5,"Wides":5,"NoBalls":0,"BattingTeam":1009,"BowlingTeam":1004,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-06-10T19:27:04.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9988,"Innings":2,"Score":203,"Overs":19,"Byes":0,"LByes":4,"Wides":8,"NoBalls":0,"BattingTeam":1004,"BowlingTeam":1009,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T19:27:04.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9987,"Season":"2025-26","Dated":"2026-05-06T19:00:00.000Z","GroundName":"Rajiv Gandhi International Stadium","Team":1,"Club":0,"ManOfMatch":19090,"ManOfMatchName":"Pat Cummins","Team1":1013,"Team2":1011,"GroundId":312,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sunrisers Hyderabad","Team2Name":"Punjab Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"SRH won by 33 runs","CityName":"Hyderabad","CountryName":"India","Innings":[{"MatchNo":9987,"Innings":1,"Score":235,"Overs":20,"Byes":2,"LByes":2,"Wides":5,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1011,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:26:47.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9987,"Innings":2,"Score":202,"Overs":20,"Byes":0,"LByes":0,"Wides":7,"NoBalls":2,"BattingTeam":1011,"BowlingTeam":1013,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-06-10T19:26:47.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9986,"Season":"2025-26","Dated":"2026-05-05T19:00:00.000Z","GroundName":"Arun Jaitley Stadium","Team":1,"Club":0,"ManOfMatch":18841,"ManOfMatchName":"Sanju Samson","Team1":1006,"Team2":1005,"GroundId":302,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Delhi Capitals","Team2Name":"Chennai Super Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"CSK won by 8 wickets (with 15 balls remaining)","CityName":"New Delhi","CountryName":"India","Innings":[{"MatchNo":9986,"Innings":1,"Score":155,"Overs":20,"Byes":0,"LByes":0,"Wides":2,"NoBalls":0,"BattingTeam":1006,"BowlingTeam":1005,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-06-10T19:24:32.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9986,"Innings":2,"Score":159,"Overs":17.3,"Byes":0,"LByes":1,"Wides":7,"NoBalls":0,"BattingTeam":1005,"BowlingTeam":1006,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-06-10T19:24:32.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9985,"Season":"2025-26","Dated":"2026-05-04T19:00:00.000Z","GroundName":"Wankhede Stadium","Team":1,"Club":0,"ManOfMatch":18790,"ManOfMatchName":"Ryan Rickelton","Team1":1009,"Team2":1010,"GroundId":303,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lucknow Super Giants","Team2Name":"Mumbai Indians","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"MI won by 6 wickets (with 8 balls remaining)","CityName":"Mumbai","CountryName":"India","Innings":[{"MatchNo":9985,"Innings":1,"Score":228,"Overs":20,"Byes":0,"LByes":0,"Wides":7,"NoBalls":4,"BattingTeam":1009,"BowlingTeam":1010,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T19:24:12.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9985,"Innings":2,"Score":229,"Overs":18.4,"Byes":0,"LByes":2,"Wides":4,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1009,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:24:12.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9900,"Season":"2025-26","Dated":"2026-05-03T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18944,"ManOfMatchName":"Aaron Hardie","Team1":1001,"Team2":996,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Peshawar Zalmi","Team2Name":"Hyderabad Kingsmen","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"Live","Official":"Official","ResultDetail":"Zalmi won by 5 wickets (with 28 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9900,"Innings":1,"Score":129,"Overs":18,"Byes":0,"LByes":3,"Wides":3,"NoBalls":1,"BattingTeam":996,"BowlingTeam":1001,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-31T10:18:30.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":18338,"ballsInCurrentOver":0,"CurrentNonStrikePlayerId":18937,"CurrentBowlerPlayerId":3436},{"MatchNo":9900,"Innings":2,"Score":130,"Overs":15.2,"Byes":0,"LByes":2,"Wides":1,"NoBalls":0,"BattingTeam":1001,"BowlingTeam":996,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-31T10:46:32.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":18931,"ballsInCurrentOver":2,"CurrentNonStrikePlayerId":18944,"CurrentBowlerPlayerId":18930}]},{"MatchNo":9984,"Season":"2025-26","Dated":"2026-05-03T19:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":4343,"ManOfMatchName":"Jason Holder","Team1":1011,"Team2":1007,"GroundId":300,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Punjab Kings","Team2Name":"Gujarat Titans","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"GT won by 4 wickets (with 1 ball remaining)","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9984,"Innings":1,"Score":163,"Overs":20,"Byes":0,"LByes":1,"Wides":7,"NoBalls":0,"BattingTeam":1011,"BowlingTeam":1007,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-06-10T19:21:35.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9984,"Innings":2,"Score":167,"Overs":19.5,"Byes":0,"LByes":2,"Wides":7,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1011,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T19:21:35.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9983,"Season":"2025-26","Dated":"2026-05-03T15:00:00.000Z","GroundName":"Rajiv Gandhi International Stadium","Team":1,"Club":0,"ManOfMatch":18674,"ManOfMatchName":"Varun Chakravarthy","Team1":1013,"Team2":1008,"GroundId":312,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sunrisers Hyderabad","Team2Name":"Kolkata Knight Riders","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"KKR won by 7 wickets (with 10 balls remaining)","CityName":"Hyderabad","CountryName":"India","Innings":[{"MatchNo":9983,"Innings":1,"Score":165,"Overs":19,"Byes":1,"LByes":0,"Wides":4,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1008,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T19:21:19.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9983,"Innings":2,"Score":169,"Overs":18.2,"Byes":0,"LByes":1,"Wides":12,"NoBalls":0,"BattingTeam":1008,"BowlingTeam":1013,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-06-10T19:21:19.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9982,"Season":"2025-26","Dated":"2026-05-02T19:00:00.000Z","GroundName":"M. A. Chidambaram Stadium","Team":1,"Club":0,"ManOfMatch":19037,"ManOfMatchName":"Ruturaj Gaikwad","Team1":1010,"Team2":1005,"GroundId":301,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Mumbai Indians","Team2Name":"Chennai Super Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"CSK won by 8 wickets (with 11 balls remaining)","CityName":"Chennai","CountryName":"India","Innings":[{"MatchNo":9982,"Innings":1,"Score":159,"Overs":20,"Byes":2,"LByes":2,"Wides":1,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1005,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-06-10T19:18:22.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9982,"Innings":2,"Score":160,"Overs":18.1,"Byes":0,"LByes":0,"Wides":4,"NoBalls":0,"BattingTeam":1005,"BowlingTeam":1010,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-06-10T19:18:22.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9937,"Season":"2025-26","Dated":"2026-05-01T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18930,"ManOfMatchName":"Hunain Shah","Team1":996,"Team2":997,"GroundId":116,"TournamentId":192,"RoundId":75,"GroupId":0,"TournamentGroup":null,"Team1Name":"Hyderabad Kingsmen","Team2Name":"Islamabad United","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kingsmen won by 2 runs","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9937,"Innings":1,"Score":186,"Overs":20,"Byes":1,"LByes":2,"Wides":5,"NoBalls":0,"BattingTeam":996,"BowlingTeam":997,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-07T11:17:04.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9937,"Innings":2,"Score":184,"Overs":20,"Byes":1,"LByes":1,"Wides":4,"NoBalls":0,"BattingTeam":997,"BowlingTeam":996,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-05-07T11:17:04.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":4,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage5Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9981,"Season":"2025-26","Dated":"2026-05-01T19:00:00.000Z","GroundName":"Sawai Mansingh Stadium","Team":1,"Club":0,"ManOfMatch":19038,"ManOfMatchName":"KL Rahul","Team1":1012,"Team2":1006,"GroundId":313,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Delhi Capitals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"DC won by 7 wickets (with 5 balls remaining)","CityName":"Jaipur","CountryName":"India","Innings":[{"MatchNo":9981,"Innings":1,"Score":225,"Overs":20,"Byes":0,"LByes":3,"Wides":6,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1006,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T19:18:08.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9981,"Innings":2,"Score":226,"Overs":19.1,"Byes":4,"LByes":1,"Wides":7,"NoBalls":1,"BattingTeam":1006,"BowlingTeam":1012,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-06-10T19:18:08.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9980,"Season":"2025-26","Dated":"2026-04-30T19:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":4343,"ManOfMatchName":"Jason Holder","Team1":1004,"Team2":1007,"GroundId":300,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Royal Challengers Bengaluru","Team2Name":"Gujarat Titans","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"GT won by 4 wickets (with 25 balls remaining)","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9980,"Innings":1,"Score":155,"Overs":19.2,"Byes":0,"LByes":3,"Wides":2,"NoBalls":0,"BattingTeam":1004,"BowlingTeam":1007,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T19:16:05.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9980,"Innings":2,"Score":158,"Overs":15.5,"Byes":0,"LByes":0,"Wides":4,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1004,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T19:16:05.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9936,"Season":"2025-26","Dated":"2026-04-29T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18577,"ManOfMatchName":"Maaz Sadaqat","Team1":996,"Team2":1000,"GroundId":116,"TournamentId":192,"RoundId":75,"GroupId":0,"TournamentGroup":null,"Team1Name":"Hyderabad Kingsmen","Team2Name":"Multan Sultan","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kingsmen won by 8 wickets (with 28 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9936,"Innings":1,"Score":159,"Overs":20,"Byes":0,"LByes":2,"Wides":9,"NoBalls":1,"BattingTeam":1000,"BowlingTeam":996,"Wickets":9,"UpdateBy":19,"UpdateTime":"2026-05-07T11:14:59.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9936,"Innings":2,"Score":162,"Overs":15.2,"Byes":4,"LByes":1,"Wides":3,"NoBalls":0,"BattingTeam":996,"BowlingTeam":1000,"Wickets":2,"UpdateBy":19,"UpdateTime":"2026-05-07T11:15:05.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9979,"Season":"2025-26","Dated":"2026-04-29T19:00:00.000Z","GroundName":"Wankhede Stadium","Team":1,"Club":0,"ManOfMatch":18984,"ManOfMatchName":"Heinrich Klaasen","Team1":1010,"Team2":1013,"GroundId":303,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Mumbai Indians","Team2Name":"Sunrisers Hyderabad","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"SRH won by 6 wickets (with 8 balls remaining)","CityName":"Mumbai","CountryName":"India","Innings":[{"MatchNo":9979,"Innings":1,"Score":243,"Overs":20,"Byes":0,"LByes":1,"Wides":7,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1013,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T19:16:01.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9979,"Innings":2,"Score":249,"Overs":18.4,"Byes":0,"LByes":4,"Wides":8,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1010,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T19:16:01.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9935,"Season":"2025-26","Dated":"2026-04-28T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":3436,"ManOfMatchName":"Babar Azam","Team1":997,"Team2":1001,"GroundId":111,"TournamentId":192,"RoundId":75,"GroupId":null,"TournamentGroup":null,"Team1Name":"Islamabad United","Team2Name":"Peshawar Zalmi","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Zalmi won by 70 runs","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9935,"Innings":1,"Score":221,"Overs":20,"Byes":0,"LByes":5,"Wides":7,"NoBalls":1,"BattingTeam":1001,"BowlingTeam":997,"Wickets":7,"UpdateBy":19,"UpdateTime":"2026-05-07T11:15:14.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9935,"Innings":2,"Score":151,"Overs":18.4,"Byes":0,"LByes":0,"Wides":7,"NoBalls":0,"BattingTeam":997,"BowlingTeam":1001,"Wickets":10,"UpdateBy":19,"UpdateTime":"2026-05-07T11:15:20.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9978,"Season":"2025-26","Dated":"2026-04-28T19:00:00.000Z","GroundName":"Maharaja Yadavindra Singh Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19054,"ManOfMatchName":"Donovan Ferreira","Team1":1011,"Team2":1012,"GroundId":315,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Punjab Kings","Team2Name":"Rajasthan Royals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RR won by 6 wickets (with 4 balls remaining)","CityName":"New Chandigarh","CountryName":"India","Innings":[{"MatchNo":9978,"Innings":1,"Score":222,"Overs":20,"Byes":4,"LByes":4,"Wides":1,"NoBalls":0,"BattingTeam":1011,"BowlingTeam":1012,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T10:23:13.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9978,"Innings":2,"Score":228,"Overs":19.2,"Byes":1,"LByes":0,"Wides":4,"NoBalls":1,"BattingTeam":1012,"BowlingTeam":1011,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T10:23:13.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9977,"Season":"2025-26","Dated":"2026-04-27T19:00:00.000Z","GroundName":"Arun Jaitley Stadium","Team":1,"Club":0,"ManOfMatch":19061,"ManOfMatchName":"Josh Hazlewood","Team1":1006,"Team2":1004,"GroundId":302,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Delhi Capitals","Team2Name":"Royal Challengers Bengaluru","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RCB won by 9 wickets (with 81 balls remaining)","CityName":"New Delhi","CountryName":"India","Innings":[{"MatchNo":9977,"Innings":1,"Score":75,"Overs":16.3,"Byes":0,"LByes":0,"Wides":4,"NoBalls":0,"BattingTeam":1006,"BowlingTeam":1004,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T10:23:08.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9977,"Innings":2,"Score":77,"Overs":6.3,"Byes":0,"LByes":0,"Wides":0,"NoBalls":0,"BattingTeam":1004,"BowlingTeam":1006,"Wickets":1,"UpdateBy":1,"UpdateTime":"2026-06-10T10:23:08.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9934,"Season":"2025-26","Dated":"2026-04-26T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18699,"ManOfMatchName":"Mark Chapman","Team1":997,"Team2":1000,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Islamabad United","Team2Name":"Multan Sultan","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"United won by 4 wickets (with 8 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9934,"Innings":1,"Score":192,"Overs":20,"Byes":2,"LByes":0,"Wides":4,"NoBalls":0,"BattingTeam":1000,"BowlingTeam":997,"Wickets":7,"UpdateBy":19,"UpdateTime":"2026-05-05T08:20:20.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9934,"Innings":2,"Score":193,"Overs":18.4,"Byes":0,"LByes":2,"Wides":12,"NoBalls":1,"BattingTeam":997,"BowlingTeam":1000,"Wickets":6,"UpdateBy":19,"UpdateTime":"2026-05-05T08:20:13.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9975,"Season":"2025-26","Dated":"2026-04-26T19:00:00.000Z","GroundName":"M. A. Chidambaram Stadium","Team":1,"Club":0,"ManOfMatch":18785,"ManOfMatchName":"Kagiso Rabada","Team1":1005,"Team2":1007,"GroundId":301,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Chennai Super Kings","Team2Name":"Gujarat Titans","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"GT won by 8 wickets (with 20 balls remaining)","CityName":"Chennai","CountryName":"India","Innings":[{"MatchNo":9975,"Innings":1,"Score":158,"Overs":20,"Byes":0,"LByes":2,"Wides":10,"NoBalls":0,"BattingTeam":1005,"BowlingTeam":1007,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-06-10T10:16:37.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9975,"Innings":2,"Score":162,"Overs":16.4,"Byes":0,"LByes":0,"Wides":2,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1005,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-06-10T10:16:37.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9976,"Season":"2025-26","Dated":"2026-04-26T19:00:00.000Z","GroundName":"Bharat Ratna Cricket Stadium","Team":1,"Club":0,"ManOfMatch":18668,"ManOfMatchName":"Rinku Singh","Team1":1008,"Team2":1009,"GroundId":314,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Kolkata Knight Riders","Team2Name":"Lucknow Super Giants","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"Match tied (KKR won the Super Over)","CityName":"Lucknow","CountryName":"India","Innings":[{"MatchNo":9976,"Innings":1,"Score":155,"Overs":20,"Byes":0,"LByes":1,"Wides":7,"NoBalls":0,"BattingTeam":1008,"BowlingTeam":1009,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-06-10T10:24:46.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9976,"Innings":2,"Score":155,"Overs":20,"Byes":2,"LByes":1,"Wides":3,"NoBalls":2,"BattingTeam":1009,"BowlingTeam":1008,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T10:24:46.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":5,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage6Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9933,"Season":"2025-26","Dated":"2026-04-26T02:30:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18930,"ManOfMatchName":"Hunain Shah","Team1":996,"Team2":1003,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Hyderabad Kingsmen","Team2Name":"Rawalpindi Pindiz","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kingsmen won by 108 runs","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9933,"Innings":1,"Score":244,"Overs":20,"Byes":0,"LByes":2,"Wides":7,"NoBalls":0,"BattingTeam":996,"BowlingTeam":1003,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-05T08:19:26.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Rawalpindi Pindiz","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9933,"Innings":2,"Score":136,"Overs":17.1,"Byes":0,"LByes":1,"Wides":1,"NoBalls":1,"BattingTeam":1003,"BowlingTeam":996,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-05T08:19:26.000Z","BattingTeamName":"Rawalpindi Pindiz","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9932,"Season":"2025-26","Dated":"2026-04-25T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":3398,"ManOfMatchName":"Fakhar Zaman","Team1":999,"Team2":1001,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lahore Qalandars","Team2Name":"Peshawar Zalmi","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Qalandars won by 6 wickets (with 3 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9932,"Innings":1,"Score":199,"Overs":20,"Byes":0,"LByes":4,"Wides":5,"NoBalls":0,"BattingTeam":1001,"BowlingTeam":999,"Wickets":4,"UpdateBy":19,"UpdateTime":"2026-05-05T08:16:00.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Lahore Qalandars","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9932,"Innings":2,"Score":200,"Overs":19.3,"Byes":0,"LByes":1,"Wides":8,"NoBalls":1,"BattingTeam":999,"BowlingTeam":1001,"Wickets":4,"UpdateBy":19,"UpdateTime":"2026-05-05T08:16:05.000Z","BattingTeamName":"Lahore Qalandars","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9973,"Season":"2025-26","Dated":"2026-04-25T19:00:00.000Z","GroundName":"Arun Jaitley Stadium","Team":1,"Club":0,"ManOfMatch":19038,"ManOfMatchName":"KL Rahul","Team1":1006,"Team2":1011,"GroundId":302,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Delhi Capitals","Team2Name":"Punjab Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"PBKS won by 6 wickets (with 7 balls remaining)","CityName":"New Delhi","CountryName":"India","Innings":[{"MatchNo":9973,"Innings":1,"Score":264,"Overs":20,"Byes":0,"LByes":0,"Wides":6,"NoBalls":1,"BattingTeam":1006,"BowlingTeam":1011,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-06-10T10:13:56.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9973,"Innings":2,"Score":265,"Overs":18.5,"Byes":0,"LByes":1,"Wides":12,"NoBalls":1,"BattingTeam":1011,"BowlingTeam":1006,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T10:13:56.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9974,"Season":"2025-26","Dated":"2026-04-25T19:00:00.000Z","GroundName":"Sawai Mansingh Stadium","Team":1,"Club":0,"ManOfMatch":18666,"ManOfMatchName":"Ishan Kishan","Team1":1012,"Team2":1013,"GroundId":313,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Sunrisers Hyderabad","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"SRH won by 5 wickets (with 9 balls remaining)","CityName":"Jaipur","CountryName":"India","Innings":[{"MatchNo":9974,"Innings":1,"Score":228,"Overs":20,"Byes":0,"LByes":1,"Wides":6,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1013,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T10:16:32.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9974,"Innings":2,"Score":229,"Overs":18.3,"Byes":0,"LByes":5,"Wides":13,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1012,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T10:16:32.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9931,"Season":"2025-26","Dated":"2026-04-25T14:30:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18938,"ManOfMatchName":"David Warner","Team1":998,"Team2":1002,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Karachi Kings","Team2Name":"Quetta Gladiators","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kings won by 9 wickets (with 9 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9931,"Innings":1,"Score":195,"Overs":20,"Byes":4,"LByes":2,"Wides":4,"NoBalls":0,"BattingTeam":1002,"BowlingTeam":998,"Wickets":6,"UpdateBy":19,"UpdateTime":"2026-05-05T08:15:45.000Z","BattingTeamName":"Quetta Gladiators","BowlingTeamName":"Karachi Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9931,"Innings":2,"Score":199,"Overs":18.3,"Byes":0,"LByes":2,"Wides":1,"NoBalls":0,"BattingTeam":998,"BowlingTeam":1002,"Wickets":1,"UpdateBy":19,"UpdateTime":"2026-05-05T08:15:52.000Z","BattingTeamName":"Karachi Kings","BowlingTeamName":"Quetta Gladiators","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9930,"Season":"2025-26","Dated":"2026-04-24T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18947,"ManOfMatchName":"Richard Gleeson","Team1":996,"Team2":997,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Hyderabad Kingsmen","Team2Name":"Islamabad United","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"United won by 8 wickets (with 80 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9930,"Innings":1,"Score":80,"Overs":15.5,"Byes":0,"LByes":0,"Wides":3,"NoBalls":0,"BattingTeam":996,"BowlingTeam":997,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-05T08:10:26.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9930,"Innings":2,"Score":83,"Overs":6.4,"Byes":0,"LByes":5,"Wides":4,"NoBalls":1,"BattingTeam":997,"BowlingTeam":996,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-05-05T08:10:26.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9972,"Season":"2025-26","Dated":"2026-04-24T19:00:00.000Z","GroundName":"M Chinnaswamy Stadium","Team":1,"Club":0,"ManOfMatch":18995,"ManOfMatchName":"Virat Kohli","Team1":1007,"Team2":1004,"GroundId":310,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Gujarat Titans","Team2Name":"Royal Challengers Bengaluru","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RCB won by 5 wickets (with 7 balls remaining)","CityName":"Bangaluru","CountryName":"India","Innings":[{"MatchNo":9972,"Innings":1,"Score":205,"Overs":20,"Byes":0,"LByes":3,"Wides":3,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1004,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-06-10T10:13:50.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9972,"Innings":2,"Score":206,"Overs":18.5,"Byes":0,"LByes":2,"Wides":3,"NoBalls":0,"BattingTeam":1004,"BowlingTeam":1007,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T10:13:50.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9929,"Season":"2025-26","Dated":"2026-04-23T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":3326,"ManOfMatchName":"Khushdil Shah","Team1":999,"Team2":998,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lahore Qalandars","Team2Name":"Karachi Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kings won by 5 wickets (with 8 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9929,"Innings":1,"Score":199,"Overs":20,"Byes":1,"LByes":1,"Wides":8,"NoBalls":0,"BattingTeam":999,"BowlingTeam":998,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-05T08:10:19.000Z","BattingTeamName":"Lahore Qalandars","BowlingTeamName":"Karachi Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9929,"Innings":2,"Score":203,"Overs":18.4,"Byes":0,"LByes":0,"Wides":10,"NoBalls":0,"BattingTeam":998,"BowlingTeam":999,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-05T08:10:19.000Z","BattingTeamName":"Karachi Kings","BowlingTeamName":"Lahore Qalandars","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9971,"Season":"2025-26","Dated":"2026-04-23T19:00:00.000Z","GroundName":"Wankhede Stadium","Team":1,"Club":0,"ManOfMatch":18841,"ManOfMatchName":"Sanju Samson","Team1":1005,"Team2":1010,"GroundId":303,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Chennai Super Kings","Team2Name":"Mumbai Indians","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"","CityName":"Mumbai","CountryName":"India","Innings":[{"MatchNo":9971,"Innings":1,"Score":207,"Overs":20,"Byes":0,"LByes":1,"Wides":5,"NoBalls":3,"BattingTeam":1005,"BowlingTeam":1010,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T10:10:20.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9971,"Innings":2,"Score":104,"Overs":19,"Byes":0,"LByes":1,"Wides":6,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1005,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T10:10:20.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9928,"Season":"2025-26","Dated":"2026-04-23T14:30:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":3523,"ManOfMatchName":"Mohammad Rizwan","Team1":997,"Team2":1003,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Islamabad United","Team2Name":"Rawalpindi Pindiz","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Rawalpindiz won by 6 wickets (with 11 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9928,"Innings":1,"Score":137,"Overs":20,"Byes":2,"LByes":1,"Wides":4,"NoBalls":1,"BattingTeam":997,"BowlingTeam":1003,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-05T08:06:18.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Rawalpindi Pindiz","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9928,"Innings":2,"Score":140,"Overs":18.1,"Byes":0,"LByes":2,"Wides":3,"NoBalls":1,"BattingTeam":1003,"BowlingTeam":997,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-05T08:06:18.000Z","BattingTeamName":"Rawalpindi Pindiz","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":6,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage7Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9927,"Season":"2025-26","Dated":"2026-04-22T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":12913,"ManOfMatchName":"Usman Khan","Team1":996,"Team2":1000,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Hyderabad Kingsmen","Team2Name":"Multan Sultan","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kingsmen won by 4 wickets (with 3 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9927,"Innings":1,"Score":213,"Overs":20,"Byes":0,"LByes":4,"Wides":1,"NoBalls":0,"BattingTeam":1000,"BowlingTeam":996,"Wickets":7,"UpdateBy":19,"UpdateTime":"2026-05-05T08:07:07.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9927,"Innings":2,"Score":214,"Overs":19.3,"Byes":1,"LByes":0,"Wides":4,"NoBalls":1,"BattingTeam":996,"BowlingTeam":1000,"Wickets":6,"UpdateBy":19,"UpdateTime":"2026-05-05T08:07:38.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9970,"Season":"2025-26","Dated":"2026-04-22T19:00:00.000Z","GroundName":"Bharat Ratna Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19027,"ManOfMatchName":"Ravindra Jadeja","Team1":1012,"Team2":1009,"GroundId":314,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Lucknow Super Giants","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RR won by 40 runs","CityName":"Lucknow","CountryName":"India","Innings":[{"MatchNo":9970,"Innings":1,"Score":159,"Overs":20,"Byes":0,"LByes":1,"Wides":4,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1009,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T10:10:14.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9970,"Innings":2,"Score":119,"Overs":18,"Byes":0,"LByes":2,"Wides":5,"NoBalls":0,"BattingTeam":1009,"BowlingTeam":1012,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T10:10:14.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9926,"Season":"2025-26","Dated":"2026-04-22T14:30:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18737,"ManOfMatchName":"Kusal Mendis","Team1":998,"Team2":1001,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Karachi Kings","Team2Name":"Peshawar Zalmi","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Zalmi won by 7 wickets (with 7 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9926,"Innings":1,"Score":182,"Overs":20,"Byes":0,"LByes":2,"Wides":6,"NoBalls":0,"BattingTeam":998,"BowlingTeam":1001,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-05-05T08:03:16.000Z","BattingTeamName":"Karachi Kings","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9926,"Innings":2,"Score":186,"Overs":18.5,"Byes":0,"LByes":0,"Wides":1,"NoBalls":1,"BattingTeam":1001,"BowlingTeam":998,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-05-05T08:03:16.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Karachi Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9925,"Season":"2025-26","Dated":"2026-04-21T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":16654,"ManOfMatchName":"Steven Smith","Team1":1000,"Team2":1003,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Multan Sultan","Team2Name":"Rawalpindi Pindiz","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Sultans won by 6 wickets (with 8 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9925,"Innings":1,"Score":166,"Overs":20,"Byes":4,"LByes":1,"Wides":7,"NoBalls":0,"BattingTeam":1000,"BowlingTeam":1003,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-05T08:03:14.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Rawalpindi Pindiz","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9925,"Innings":2,"Score":167,"Overs":18.4,"Byes":0,"LByes":4,"Wides":5,"NoBalls":1,"BattingTeam":1003,"BowlingTeam":1000,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-05T08:03:14.000Z","BattingTeamName":"Rawalpindi Pindiz","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9969,"Season":"2025-26","Dated":"2026-04-21T19:00:00.000Z","GroundName":"Rajiv Gandhi International Stadium","Team":1,"Club":0,"ManOfMatch":18662,"ManOfMatchName":"Abhishek Sharma","Team1":1013,"Team2":1006,"GroundId":312,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sunrisers Hyderabad","Team2Name":"Delhi Capitals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"SRH won by 47 runs","CityName":"Hyderabad","CountryName":"India","Innings":[{"MatchNo":9969,"Innings":1,"Score":242,"Overs":20,"Byes":0,"LByes":0,"Wides":8,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1006,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-06-10T10:07:20.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9969,"Innings":2,"Score":195,"Overs":20,"Byes":0,"LByes":1,"Wides":7,"NoBalls":0,"BattingTeam":1006,"BowlingTeam":1013,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-06-10T10:07:20.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9924,"Season":"2025-26","Dated":"2026-04-21T14:30:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":3398,"ManOfMatchName":"Fakhar Zaman","Team1":999,"Team2":1002,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":null,"TournamentGroup":null,"Team1Name":"Lahore Qalandars","Team2Name":"Quetta Gladiators","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Qalandars won by 9 runs","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9924,"Innings":1,"Score":197,"Overs":20,"Byes":0,"LByes":3,"Wides":10,"NoBalls":1,"BattingTeam":999,"BowlingTeam":1002,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-04T19:24:44.000Z","BattingTeamName":"Lahore Qalandars","BowlingTeamName":"Quetta Gladiators","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9924,"Innings":2,"Score":188,"Overs":20,"Byes":2,"LByes":2,"Wides":3,"NoBalls":1,"BattingTeam":1002,"BowlingTeam":999,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-05-04T19:24:44.000Z","BattingTeamName":"Quetta Gladiators","BowlingTeamName":"Lahore Qalandars","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9968,"Season":"2025-26","Dated":"2026-04-20T19:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":18672,"ManOfMatchName":"Tilak Varma","Team1":1010,"Team2":1007,"GroundId":300,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Mumbai Indians","Team2Name":"Gujarat Titans","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9968,"Innings":1,"Score":199,"Overs":20,"Byes":1,"LByes":4,"Wides":2,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1007,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T10:07:11.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9968,"Innings":2,"Score":100,"Overs":15.5,"Byes":0,"LByes":0,"Wides":7,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1010,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T10:07:11.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9923,"Season":"2025-26","Dated":"2026-04-19T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":3436,"ManOfMatchName":"Babar Azam","Team1":1001,"Team2":1002,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Peshawar Zalmi","Team2Name":"Quetta Gladiators","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Zalmi won by 118 runs","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9923,"Innings":1,"Score":255,"Overs":20,"Byes":1,"LByes":1,"Wides":9,"NoBalls":0,"BattingTeam":1001,"BowlingTeam":1002,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-05-04T19:24:42.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Quetta Gladiators","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9923,"Innings":2,"Score":137,"Overs":18.1,"Byes":4,"LByes":5,"Wides":3,"NoBalls":0,"BattingTeam":1002,"BowlingTeam":1001,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-04T19:24:42.000Z","BattingTeamName":"Quetta Gladiators","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9967,"Season":"2025-26","Dated":"2026-04-19T19:00:00.000Z","GroundName":"Maharaja Yadavindra Singh Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19017,"ManOfMatchName":"Priyansh Arya","Team1":1011,"Team2":1009,"GroundId":315,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Punjab Kings","Team2Name":"Lucknow Super Giants","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"PBKS won by 54 runs","CityName":"New Chandigarh","CountryName":"India","Innings":[{"MatchNo":9967,"Innings":1,"Score":254,"Overs":20,"Byes":0,"LByes":3,"Wides":6,"NoBalls":0,"BattingTeam":1011,"BowlingTeam":1009,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-06-10T10:04:43.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9967,"Innings":2,"Score":200,"Overs":20,"Byes":0,"LByes":2,"Wides":6,"NoBalls":1,"BattingTeam":1009,"BowlingTeam":1011,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T10:04:43.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9966,"Season":"2025-26","Dated":"2026-04-19T15:00:00.000Z","GroundName":"Eden Gardens","Team":1,"Club":0,"ManOfMatch":18674,"ManOfMatchName":"Varun Chakravarthy","Team1":1012,"Team2":1008,"GroundId":304,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Kolkata Knight Riders","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"KKR won by 4 wickets (with 2 balls remaining)","CityName":"Kolkata","CountryName":"India","Innings":[{"MatchNo":9966,"Innings":1,"Score":155,"Overs":20,"Byes":1,"LByes":2,"Wides":10,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1008,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-06-10T10:04:36.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9966,"Innings":2,"Score":161,"Overs":19.4,"Byes":0,"LByes":1,"Wides":8,"NoBalls":0,"BattingTeam":1008,"BowlingTeam":1012,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T10:04:36.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":7,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage8Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9922,"Season":"2025-26","Dated":"2026-04-19T14:30:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18949,"ManOfMatchName":"Arafat Minhas","Team1":998,"Team2":1000,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":null,"TournamentGroup":null,"Team1Name":"Karachi Kings","Team2Name":"Multan Sultan","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Sultans won by 11 runs","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9922,"Innings":1,"Score":207,"Overs":20,"Byes":0,"LByes":0,"Wides":5,"NoBalls":3,"BattingTeam":1000,"BowlingTeam":998,"Wickets":7,"UpdateBy":19,"UpdateTime":"2026-05-04T19:21:17.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Karachi Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9922,"Innings":2,"Score":196,"Overs":19.4,"Byes":0,"LByes":8,"Wides":9,"NoBalls":2,"BattingTeam":998,"BowlingTeam":1000,"Wickets":10,"UpdateBy":19,"UpdateTime":"2026-05-04T19:21:11.000Z","BattingTeamName":"Karachi Kings","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9921,"Season":"2025-26","Dated":"2026-04-18T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":3398,"ManOfMatchName":"Fakhar Zaman","Team1":999,"Team2":1003,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lahore Qalandars","Team2Name":"Rawalpindi Pindiz","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Qalandars won by 32 runs","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9921,"Innings":1,"Score":210,"Overs":20,"Byes":4,"LByes":2,"Wides":15,"NoBalls":1,"BattingTeam":999,"BowlingTeam":1003,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-04T19:20:35.000Z","BattingTeamName":"Lahore Qalandars","BowlingTeamName":"Rawalpindi Pindiz","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9921,"Innings":2,"Score":178,"Overs":20,"Byes":0,"LByes":6,"Wides":1,"NoBalls":1,"BattingTeam":1003,"BowlingTeam":999,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-05-04T19:20:35.000Z","BattingTeamName":"Rawalpindi Pindiz","BowlingTeamName":"Lahore Qalandars","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9964,"Season":"2025-26","Dated":"2026-04-18T19:00:00.000Z","GroundName":"M Chinnaswamy Stadium","Team":1,"Club":0,"ManOfMatch":18791,"ManOfMatchName":"Tristan Stubbs","Team1":1004,"Team2":1006,"GroundId":310,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Royal Challengers Bengaluru","Team2Name":"Delhi Capitals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"DC won by 6 wickets (with 1 ball remaining)","CityName":"Bangaluru","CountryName":"India","Innings":[{"MatchNo":9964,"Innings":1,"Score":175,"Overs":20,"Byes":0,"LByes":2,"Wides":8,"NoBalls":1,"BattingTeam":1004,"BowlingTeam":1006,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T09:59:35.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9964,"Innings":2,"Score":179,"Overs":19.5,"Byes":0,"LByes":3,"Wides":2,"NoBalls":1,"BattingTeam":1006,"BowlingTeam":1004,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-06-10T09:59:35.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9965,"Season":"2025-26","Dated":"2026-04-18T19:00:00.000Z","GroundName":"Rajiv Gandhi International Stadium","Team":1,"Club":0,"ManOfMatch":18981,"ManOfMatchName":"Eshan Malinga","Team1":1013,"Team2":1005,"GroundId":312,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sunrisers Hyderabad","Team2Name":"Chennai Super Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"SRH won by 10 runs","CityName":"Hyderabad","CountryName":"India","Innings":[{"MatchNo":9965,"Innings":1,"Score":194,"Overs":20,"Byes":5,"LByes":4,"Wides":4,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1005,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-06-10T09:56:34.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9965,"Innings":2,"Score":184,"Overs":20,"Byes":0,"LByes":1,"Wides":15,"NoBalls":2,"BattingTeam":1005,"BowlingTeam":1013,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-06-10T09:56:34.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9920,"Season":"2025-26","Dated":"2026-04-17T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":3801,"ManOfMatchName":"Usman Tariq","Team1":999,"Team2":1002,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lahore Qalandars","Team2Name":"Quetta Gladiators","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Gladiators won by 6 wickets (with 22 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9920,"Innings":1,"Score":134,"Overs":19.5,"Byes":0,"LByes":0,"Wides":0,"NoBalls":3,"BattingTeam":999,"BowlingTeam":1002,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-04T19:17:01.000Z","BattingTeamName":"Lahore Qalandars","BowlingTeamName":"Quetta Gladiators","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9920,"Innings":2,"Score":138,"Overs":16.2,"Byes":0,"LByes":4,"Wides":7,"NoBalls":0,"BattingTeam":1002,"BowlingTeam":999,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-04T19:17:01.000Z","BattingTeamName":"Quetta Gladiators","BowlingTeamName":"Lahore Qalandars","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9919,"Season":"2025-26","Dated":"2026-04-16T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18948,"ManOfMatchName":"Sameer Minhas","Team1":998,"Team2":997,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Karachi Kings","Team2Name":"Islamabad United","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"United won by 8 wickets (with 24 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9919,"Innings":1,"Score":150,"Overs":20,"Byes":0,"LByes":2,"Wides":4,"NoBalls":0,"BattingTeam":998,"BowlingTeam":997,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-04T19:17:02.000Z","BattingTeamName":"Karachi Kings","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9919,"Innings":2,"Score":153,"Overs":16,"Byes":0,"LByes":2,"Wides":4,"NoBalls":0,"BattingTeam":997,"BowlingTeam":998,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-05-04T19:17:02.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Karachi Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9962,"Season":"2025-26","Dated":"2026-04-16T19:00:00.000Z","GroundName":"Wankhede Stadium","Team":1,"Club":0,"ManOfMatch":18663,"ManOfMatchName":"Arshdeep Singh","Team1":1010,"Team2":1011,"GroundId":303,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Mumbai Indians","Team2Name":"Punjab Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"PBKS won by 7 wickets (with 21 balls remaining)","CityName":"Mumbai","CountryName":"India","Innings":[{"MatchNo":9962,"Innings":1,"Score":195,"Overs":20,"Byes":0,"LByes":4,"Wides":4,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1011,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-06-10T09:52:38.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9962,"Innings":2,"Score":198,"Overs":16.3,"Byes":0,"LByes":0,"Wides":9,"NoBalls":1,"BattingTeam":1011,"BowlingTeam":1010,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-06-10T09:52:38.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9963,"Season":"2025-26","Dated":"2026-04-16T19:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":19014,"ManOfMatchName":"Shubman Gill","Team1":1008,"Team2":1007,"GroundId":300,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Kolkata Knight Riders","Team2Name":"Gujarat Titans","Type":"Friendly","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"GT won by 5 wickets (with 2 balls remaining)","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9963,"Innings":1,"Score":180,"Overs":20,"Byes":4,"LByes":3,"Wides":6,"NoBalls":1,"BattingTeam":1008,"BowlingTeam":1007,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T09:53:45.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9963,"Innings":2,"Score":181,"Overs":19.4,"Byes":0,"LByes":2,"Wides":4,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1008,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T09:53:45.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9918,"Season":"2025-26","Dated":"2026-04-16T14:30:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18930,"ManOfMatchName":"Hunain Shah","Team1":996,"Team2":1003,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":null,"TournamentGroup":null,"Team1Name":"Hyderabad Kingsmen","Team2Name":"Rawalpindi Pindiz","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kingsmen won by 5 wickets (with 21 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9918,"Innings":1,"Score":121,"Overs":20,"Byes":0,"LByes":4,"Wides":1,"NoBalls":0,"BattingTeam":996,"BowlingTeam":1003,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-05-04T19:13:58.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Rawalpindi Pindiz","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9918,"Innings":2,"Score":123,"Overs":16.3,"Byes":0,"LByes":3,"Wides":3,"NoBalls":0,"BattingTeam":1003,"BowlingTeam":996,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-04T19:13:58.000Z","BattingTeamName":"Rawalpindi Pindiz","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9917,"Season":"2025-26","Dated":"2026-04-15T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18936,"ManOfMatchName":"Sufyan Moqim","Team1":1001,"Team2":1002,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Peshawar Zalmi","Team2Name":"Quetta Gladiators","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Zalmi won by 8 wickets (with 9 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9917,"Innings":1,"Score":154,"Overs":20,"Byes":0,"LByes":5,"Wides":2,"NoBalls":1,"BattingTeam":1001,"BowlingTeam":1002,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-04T19:13:57.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Quetta Gladiators","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9917,"Innings":2,"Score":156,"Overs":18.3,"Byes":2,"LByes":3,"Wides":5,"NoBalls":1,"BattingTeam":1002,"BowlingTeam":1001,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-05-04T19:13:57.000Z","BattingTeamName":"Quetta Gladiators","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":8,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage9Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9961,"Season":"2025-26","Dated":"2026-04-15T19:00:00.000Z","GroundName":"M Chinnaswamy Stadium","Team":1,"Club":0,"ManOfMatch":19061,"ManOfMatchName":"Josh Hazlewood","Team1":1009,"Team2":1004,"GroundId":310,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lucknow Super Giants","Team2Name":"Royal Challengers Bengaluru","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RCB won by 5 wickets (with 29 balls remaining)","CityName":"Bangaluru","CountryName":"India","Innings":[{"MatchNo":9961,"Innings":1,"Score":146,"Overs":20,"Byes":1,"LByes":2,"Wides":4,"NoBalls":0,"BattingTeam":1009,"BowlingTeam":1004,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-06-10T09:51:16.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9961,"Innings":2,"Score":149,"Overs":15.1,"Byes":0,"LByes":4,"Wides":1,"NoBalls":0,"BattingTeam":1004,"BowlingTeam":1009,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T09:51:16.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9960,"Season":"2025-26","Dated":"2026-04-14T19:00:00.000Z","GroundName":"M. A. Chidambaram Stadium","Team":1,"Club":0,"ManOfMatch":18566,"ManOfMatchName":"Noor Ahmad ","Team1":1005,"Team2":1008,"GroundId":301,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Chennai Super Kings","Team2Name":"Kolkata Knight Riders","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"CSK won by 32 runs","CityName":"Chennai","CountryName":"India","Innings":[{"MatchNo":9960,"Innings":1,"Score":192,"Overs":20,"Byes":0,"LByes":4,"Wides":11,"NoBalls":0,"BattingTeam":1005,"BowlingTeam":1008,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-06-10T09:49:41.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9960,"Innings":2,"Score":160,"Overs":20,"Byes":0,"LByes":2,"Wides":5,"NoBalls":0,"BattingTeam":1008,"BowlingTeam":1005,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-06-10T09:49:41.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9916,"Season":"2025-26","Dated":"2026-04-13T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18936,"ManOfMatchName":"Sufyan Moqim","Team1":1000,"Team2":1001,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Multan Sultan","Team2Name":"Peshawar Zalmi","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Zalmi won by 24 runs","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9916,"Innings":1,"Score":196,"Overs":20,"Byes":4,"LByes":3,"Wides":5,"NoBalls":0,"BattingTeam":1000,"BowlingTeam":1001,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-04T19:10:51.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9916,"Innings":2,"Score":172,"Overs":20,"Byes":0,"LByes":3,"Wides":8,"NoBalls":0,"BattingTeam":1001,"BowlingTeam":1000,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-04T19:10:51.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9958,"Season":"2025-26","Dated":"2026-04-13T19:00:00.000Z","GroundName":"Rajiv Gandhi International Stadium","Team":1,"Club":0,"ManOfMatch":19068,"ManOfMatchName":"Praful Hinge","Team1":1013,"Team2":1012,"GroundId":312,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sunrisers Hyderabad","Team2Name":"Rajasthan Royals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"SRH won by 57 runs","CityName":"Hyderabad","CountryName":"India","Innings":[{"MatchNo":9958,"Innings":1,"Score":216,"Overs":20,"Byes":0,"LByes":1,"Wides":8,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1012,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-31T09:35:02.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9958,"Innings":2,"Score":159,"Overs":19,"Byes":0,"LByes":1,"Wides":9,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1013,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-31T09:35:02.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9915,"Season":"2025-26","Dated":"2026-04-12T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18924,"ManOfMatchName":"Marnus Labuschagne","Team1":996,"Team2":997,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Hyderabad Kingsmen","Team2Name":"Islamabad United","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kingsmen won by 6 wickets (with 11 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9915,"Innings":1,"Score":153,"Overs":20,"Byes":0,"LByes":4,"Wides":2,"NoBalls":0,"BattingTeam":996,"BowlingTeam":997,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-05-04T19:10:49.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9915,"Innings":2,"Score":157,"Overs":18.1,"Byes":1,"LByes":1,"Wides":4,"NoBalls":1,"BattingTeam":997,"BowlingTeam":996,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-04T19:10:49.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9956,"Season":"2025-26","Dated":"2026-04-12T19:00:00.000Z","GroundName":"Bharat Ratna Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19011,"ManOfMatchName":"Prasidh Krishna","Team1":1009,"Team2":1007,"GroundId":314,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lucknow Super Giants","Team2Name":"Gujarat Titans","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"GT won by 7 wickets (with 8 balls remaining)","CityName":"Lucknow","CountryName":"India","Innings":[{"MatchNo":9956,"Innings":1,"Score":164,"Overs":20,"Byes":1,"LByes":5,"Wides":3,"NoBalls":0,"BattingTeam":1009,"BowlingTeam":1007,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-31T09:28:47.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9956,"Innings":2,"Score":165,"Overs":18.4,"Byes":0,"LByes":0,"Wides":3,"NoBalls":0,"BattingTeam":1007,"BowlingTeam":1009,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-05-31T09:28:47.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9957,"Season":"2025-26","Dated":"2026-04-12T19:00:00.000Z","GroundName":"Wankhede Stadium","Team":1,"Club":0,"ManOfMatch":16662,"ManOfMatchName":"Phil Salt","Team1":1004,"Team2":1010,"GroundId":303,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Royal Challengers Bengaluru","Team2Name":"Mumbai Indians","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RCB won by 18 runs","CityName":"Mumbai","CountryName":"India","Innings":[{"MatchNo":9957,"Innings":1,"Score":240,"Overs":20,"Byes":0,"LByes":1,"Wides":11,"NoBalls":1,"BattingTeam":1004,"BowlingTeam":1010,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-31T09:30:57.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9957,"Innings":2,"Score":222,"Overs":20,"Byes":0,"LByes":2,"Wides":9,"NoBalls":1,"BattingTeam":1010,"BowlingTeam":1004,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-31T09:30:57.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9914,"Season":"2025-26","Dated":"2026-04-11T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":6291,"ManOfMatchName":"Hassan Khan","Team1":998,"Team2":996,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Karachi Kings","Team2Name":"Hyderabad Kingsmen","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kingsmen won by 4 wickets (with 5 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9914,"Innings":1,"Score":188,"Overs":20,"Byes":0,"LByes":0,"Wides":5,"NoBalls":1,"BattingTeam":998,"BowlingTeam":996,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-04T19:07:50.000Z","BattingTeamName":"Karachi Kings","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9914,"Innings":2,"Score":189,"Overs":19.1,"Byes":0,"LByes":9,"Wides":2,"NoBalls":1,"BattingTeam":996,"BowlingTeam":998,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-04T19:07:50.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Karachi Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9954,"Season":"2025-26","Dated":"2026-04-11T19:00:00.000Z","GroundName":"Maharaja Yadavindra Singh Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19019,"ManOfMatchName":"Shreyas Iyer","Team1":1013,"Team2":1011,"GroundId":315,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sunrisers Hyderabad","Team2Name":"Punjab Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"PBKS won by 6 wickets (with 7 balls remaining)","CityName":"New Chandigarh","CountryName":"India","Innings":[{"MatchNo":9954,"Innings":1,"Score":219,"Overs":20,"Byes":1,"LByes":0,"Wides":11,"NoBalls":1,"BattingTeam":1013,"BowlingTeam":1011,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-31T09:25:19.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9954,"Innings":2,"Score":223,"Overs":18.5,"Byes":0,"LByes":0,"Wides":5,"NoBalls":0,"BattingTeam":1011,"BowlingTeam":1013,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-31T09:25:19.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9955,"Season":"2025-26","Dated":"2026-04-11T19:00:00.000Z","GroundName":"M. A. Chidambaram Stadium","Team":1,"Club":0,"ManOfMatch":18841,"ManOfMatchName":"Sanju Samson","Team1":1005,"Team2":1006,"GroundId":301,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Chennai Super Kings","Team2Name":"Delhi Capitals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"CSK won by 23 runs","CityName":"Chennai","CountryName":"India","Innings":[{"MatchNo":9955,"Innings":1,"Score":212,"Overs":20,"Byes":0,"LByes":0,"Wides":3,"NoBalls":0,"BattingTeam":1005,"BowlingTeam":1006,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-05-31T09:27:09.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9955,"Innings":2,"Score":189,"Overs":20,"Byes":0,"LByes":1,"Wides":11,"NoBalls":3,"BattingTeam":1006,"BowlingTeam":1005,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-31T09:27:09.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":9,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage10Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9913,"Season":"2025-26","Dated":"2026-04-11T14:30:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18737,"ManOfMatchName":"Kusal Mendis","Team1":999,"Team2":1001,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lahore Qalandars","Team2Name":"Peshawar Zalmi","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Zalmi won by 76 runs","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9913,"Innings":1,"Score":173,"Overs":20,"Byes":0,"LByes":2,"Wides":3,"NoBalls":0,"BattingTeam":999,"BowlingTeam":1001,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-05-04T19:07:47.000Z","BattingTeamName":"Lahore Qalandars","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9913,"Innings":2,"Score":97,"Overs":17,"Byes":0,"LByes":1,"Wides":2,"NoBalls":0,"BattingTeam":1001,"BowlingTeam":999,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-04T19:07:47.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Lahore Qalandars","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9912,"Season":"2025-26","Dated":"2026-04-10T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":8202,"ManOfMatchName":"Rilee Rossouw","Team1":1002,"Team2":1003,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Quetta Gladiators","Team2Name":"Rawalpindi Pindiz","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Gladiators won by 61 runs","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9912,"Innings":1,"Score":182,"Overs":20,"Byes":6,"LByes":2,"Wides":1,"NoBalls":0,"BattingTeam":1002,"BowlingTeam":1003,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-04T19:04:05.000Z","BattingTeamName":"Quetta Gladiators","BowlingTeamName":"Rawalpindi Pindiz","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9912,"Innings":2,"Score":121,"Overs":17.3,"Byes":0,"LByes":1,"Wides":1,"NoBalls":1,"BattingTeam":1003,"BowlingTeam":1002,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-04T19:04:05.000Z","BattingTeamName":"Rawalpindi Pindiz","BowlingTeamName":"Quetta Gladiators","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9953,"Season":"2025-26","Dated":"2026-04-10T19:00:00.000Z","GroundName":"Barsapara Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19031,"ManOfMatchName":"Vaibhav Sooryavanshi","Team1":1004,"Team2":1012,"GroundId":311,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Royal Challengers Bengaluru","Team2Name":"Rajasthan Royals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RR won by 6 wickets (with 12 balls remaining)","CityName":"Guwahati","CountryName":"India","Innings":[{"MatchNo":9953,"Innings":1,"Score":201,"Overs":20,"Byes":4,"LByes":2,"Wides":7,"NoBalls":0,"BattingTeam":1004,"BowlingTeam":1012,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-31T09:23:14.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9953,"Innings":2,"Score":202,"Overs":18,"Byes":0,"LByes":1,"Wides":2,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1004,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-31T09:23:14.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9910,"Season":"2025-26","Dated":"2026-04-09T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":8208,"ManOfMatchName":"Chris Green","Team1":997,"Team2":999,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Islamabad United","Team2Name":"Lahore Qalandars","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"United won by 9 wickets (with 58 balls remaining)","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9910,"Innings":1,"Score":100,"Overs":18.3,"Byes":2,"LByes":6,"Wides":4,"NoBalls":1,"BattingTeam":999,"BowlingTeam":997,"Wickets":10,"UpdateBy":19,"UpdateTime":"2026-05-04T19:01:18.000Z","BattingTeamName":"Lahore Qalandars","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9910,"Innings":2,"Score":104,"Overs":10.2,"Byes":0,"LByes":5,"Wides":1,"NoBalls":0,"BattingTeam":997,"BowlingTeam":999,"Wickets":1,"UpdateBy":19,"UpdateTime":"2026-05-04T19:01:24.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Lahore Qalandars","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9911,"Season":"2025-26","Dated":"2026-04-09T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":18737,"ManOfMatchName":"Kusal Mendis","Team1":998,"Team2":1001,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Karachi Kings","Team2Name":"Peshawar Zalmi","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Zalmi won by 159 runs","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9911,"Innings":1,"Score":246,"Overs":20,"Byes":0,"LByes":1,"Wides":3,"NoBalls":0,"BattingTeam":998,"BowlingTeam":1001,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-05-04T19:04:07.000Z","BattingTeamName":"Karachi Kings","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9911,"Innings":2,"Score":87,"Overs":16.1,"Byes":0,"LByes":2,"Wides":6,"NoBalls":1,"BattingTeam":1001,"BowlingTeam":998,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-04T19:04:07.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Karachi Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9952,"Season":"2025-26","Dated":"2026-04-09T19:00:00.000Z","GroundName":"Eden Gardens","Team":1,"Club":0,"ManOfMatch":19046,"ManOfMatchName":"Mukul Choudhary","Team1":1008,"Team2":1009,"GroundId":304,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Kolkata Knight Riders","Team2Name":"Lucknow Super Giants","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"LSG won by 3 wickets (with 0 balls remaining)","CityName":"Kolkata","CountryName":"India","Innings":[{"MatchNo":9952,"Innings":1,"Score":181,"Overs":20,"Byes":1,"LByes":3,"Wides":7,"NoBalls":0,"BattingTeam":1008,"BowlingTeam":1009,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-29T09:46:46.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9952,"Innings":2,"Score":182,"Overs":20,"Byes":1,"LByes":2,"Wides":6,"NoBalls":1,"BattingTeam":1009,"BowlingTeam":1008,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-05-29T09:46:46.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9895,"Season":"2025-26","Dated":"2026-04-08T19:00:00.000Z","GroundName":"National Stadium Karachi","Team":1,"Club":0,"ManOfMatch":3511,"ManOfMatchName":"Iftikhar Ahmed","Team1":996,"Team2":1001,"GroundId":111,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Hyderabad Kingsmen","Team2Name":"Peshawar Zalmi","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Zalmi won by 4 wickets","CityName":"Karachi","CountryName":"Pakistan","Innings":[{"MatchNo":9895,"Innings":1,"Score":145,"Overs":18.2,"Byes":4,"LByes":4,"Wides":1,"NoBalls":0,"BattingTeam":996,"BowlingTeam":1001,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-02T12:20:10.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9895,"Innings":2,"Score":146,"Overs":20,"Byes":0,"LByes":2,"Wides":1,"NoBalls":0,"BattingTeam":1001,"BowlingTeam":996,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-02T12:20:10.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9951,"Season":"2025-26","Dated":"2026-04-08T19:00:00.000Z","GroundName":"Arun Jaitley Stadium","Team":1,"Club":0,"ManOfMatch":18490,"ManOfMatchName":"Rashid Khan ","Team1":1007,"Team2":1006,"GroundId":302,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Gujarat Titans","Team2Name":"Delhi Capitals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"GT won by 1 run","CityName":"New Delhi","CountryName":"India","Innings":[{"MatchNo":9951,"Innings":1,"Score":210,"Overs":20,"Byes":0,"LByes":0,"Wides":5,"NoBalls":1,"BattingTeam":1007,"BowlingTeam":1006,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-29T09:44:31.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9951,"Innings":2,"Score":209,"Overs":20,"Byes":0,"LByes":0,"Wides":8,"NoBalls":0,"BattingTeam":1006,"BowlingTeam":1007,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-29T09:44:31.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9909,"Season":"2025-26","Dated":"2026-04-06T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18581,"ManOfMatchName":"Faisal Akram","Team1":1000,"Team2":1003,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Multan Sultan","Team2Name":"Rawalpindi Pindiz","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Sultans won by 7 wickets (with 22 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9909,"Innings":1,"Score":182,"Overs":20,"Byes":0,"LByes":1,"Wides":3,"NoBalls":0,"BattingTeam":1000,"BowlingTeam":1003,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-04T19:00:39.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Rawalpindi Pindiz","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9909,"Innings":2,"Score":186,"Overs":16.2,"Byes":0,"LByes":4,"Wides":0,"NoBalls":0,"BattingTeam":1003,"BowlingTeam":1000,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-05-04T19:00:39.000Z","BattingTeamName":"Rawalpindi Pindiz","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9949,"Season":"2025-26","Dated":"2026-04-06T19:00:00.000Z","GroundName":"Eden Gardens","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":1008,"Team2":1011,"GroundId":304,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Kolkata Knight Riders","Team2Name":"Punjab Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"No result","CityName":"Kolkata","CountryName":"India","Innings":[]}],"pagination":{"current_page":10,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage11Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9950,"Season":"2025-26","Dated":"2026-04-06T19:00:00.000Z","GroundName":"Barsapara Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19032,"ManOfMatchName":"Yashasvi Jaiswal","Team1":1012,"Team2":1010,"GroundId":311,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Mumbai Indians","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RR won by 27 runs","CityName":"Guwahati","CountryName":"India","Innings":[{"MatchNo":9950,"Innings":1,"Score":150,"Overs":11,"Byes":0,"LByes":0,"Wides":6,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1010,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-05-29T09:41:50.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9950,"Innings":2,"Score":123,"Overs":11,"Byes":1,"LByes":4,"Wides":6,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1012,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-05-29T09:41:50.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9908,"Season":"2025-26","Dated":"2026-04-05T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":80,"ManOfMatchName":"Mohammad Nawaz","Team1":1000,"Team2":1002,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Multan Sultan","Team2Name":"Quetta Gladiators","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Sultans won by 6 wickets (with 15 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9908,"Innings":1,"Score":166,"Overs":20,"Byes":0,"LByes":1,"Wides":2,"NoBalls":0,"BattingTeam":1000,"BowlingTeam":1002,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-05-04T18:55:28.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Quetta Gladiators","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9908,"Innings":2,"Score":167,"Overs":17.3,"Byes":0,"LByes":1,"Wides":7,"NoBalls":0,"BattingTeam":1002,"BowlingTeam":1000,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-04T18:55:28.000Z","BattingTeamName":"Quetta Gladiators","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9948,"Season":"2025-26","Dated":"2026-04-05T19:00:00.000Z","GroundName":"M Chinnaswamy Stadium","Team":1,"Club":0,"ManOfMatch":18569,"ManOfMatchName":"Tim David","Team1":1004,"Team2":1005,"GroundId":310,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Royal Challengers Bengaluru","Team2Name":"Chennai Super Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RCB won by 43 runs","CityName":"Bangaluru","CountryName":"India","Innings":[{"MatchNo":9948,"Innings":1,"Score":250,"Overs":20,"Byes":1,"LByes":3,"Wides":3,"NoBalls":1,"BattingTeam":1004,"BowlingTeam":1005,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-05-29T09:36:30.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9948,"Innings":2,"Score":207,"Overs":19.4,"Byes":0,"LByes":2,"Wides":3,"NoBalls":2,"BattingTeam":1005,"BowlingTeam":1004,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-29T09:36:30.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9947,"Season":"2025-26","Dated":"2026-04-05T15:00:00.000Z","GroundName":"Rajiv Gandhi International Stadium","Team":1,"Club":0,"ManOfMatch":19045,"ManOfMatchName":"Mohammed Shami","Team1":1013,"Team2":1009,"GroundId":312,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sunrisers Hyderabad","Team2Name":"Lucknow Super Giants","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"LSG won by 5 wickets (with 1 ball remaining)","CityName":"Hyderabad","CountryName":"India","Innings":[{"MatchNo":9947,"Innings":1,"Score":156,"Overs":20,"Byes":1,"LByes":1,"Wides":3,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1009,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-05-29T09:31:12.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9947,"Innings":2,"Score":160,"Overs":19.5,"Byes":1,"LByes":1,"Wides":0,"NoBalls":0,"BattingTeam":1009,"BowlingTeam":1013,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-29T09:31:12.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9907,"Season":"2025-26","Dated":"2026-04-04T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18948,"ManOfMatchName":"Sameer Minhas","Team1":997,"Team2":1003,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":null,"TournamentGroup":null,"Team1Name":"Islamabad United","Team2Name":"Rawalpindi Pindiz","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"United won by 7 wickets (with 34 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9907,"Innings":1,"Score":156,"Overs":20,"Byes":0,"LByes":3,"Wides":3,"NoBalls":0,"BattingTeam":997,"BowlingTeam":1003,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-05-04T18:55:31.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Rawalpindi Pindiz","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9907,"Innings":2,"Score":157,"Overs":14.2,"Byes":0,"LByes":4,"Wides":8,"NoBalls":0,"BattingTeam":1003,"BowlingTeam":997,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-05-04T18:55:31.000Z","BattingTeamName":"Rawalpindi Pindiz","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9945,"Season":"2025-26","Dated":"2026-04-04T19:00:00.000Z","GroundName":"Arun Jaitley Stadium","Team":1,"Club":0,"ManOfMatch":19041,"ManOfMatchName":"Sameer Rizvi","Team1":1010,"Team2":1006,"GroundId":302,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Mumbai Indians","Team2Name":"Delhi Capitals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"DC won by 6 wickets (with 11 balls remaining)","CityName":"New Delhi","CountryName":"India","Innings":[{"MatchNo":9945,"Innings":1,"Score":162,"Overs":20,"Byes":0,"LByes":1,"Wides":4,"NoBalls":0,"BattingTeam":1010,"BowlingTeam":1006,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-29T09:26:57.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9945,"Innings":2,"Score":164,"Overs":18.1,"Byes":0,"LByes":1,"Wides":4,"NoBalls":0,"BattingTeam":1006,"BowlingTeam":1010,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-29T09:26:57.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9946,"Season":"2025-26","Dated":"2026-04-04T19:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":19026,"ManOfMatchName":"Ravi Bishnoi","Team1":1012,"Team2":1007,"GroundId":300,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Gujarat Titans","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RR won by 6 runs","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9946,"Innings":1,"Score":210,"Overs":20,"Byes":0,"LByes":1,"Wides":13,"NoBalls":0,"BattingTeam":1012,"BowlingTeam":1007,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-29T09:29:22.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9946,"Innings":2,"Score":204,"Overs":20,"Byes":1,"LByes":1,"Wides":7,"NoBalls":1,"BattingTeam":1007,"BowlingTeam":1012,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-29T09:29:22.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9905,"Season":"2025-26","Dated":"2026-04-03T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":12294,"ManOfMatchName":"Mohammad Naeem ","Team1":999,"Team2":1000,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":null,"TournamentGroup":null,"Team1Name":"Lahore Qalandars","Team2Name":"Multan Sultan","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Qalandars won by 20 runs","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9905,"Innings":1,"Score":185,"Overs":13,"Byes":4,"LByes":3,"Wides":14,"NoBalls":2,"BattingTeam":999,"BowlingTeam":1000,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-04T18:52:04.000Z","BattingTeamName":"Lahore Qalandars","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9905,"Innings":2,"Score":165,"Overs":13,"Byes":0,"LByes":2,"Wides":6,"NoBalls":1,"BattingTeam":1000,"BowlingTeam":999,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-04T18:52:04.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Lahore Qalandars","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9944,"Season":"2025-26","Dated":"2026-04-03T19:00:00.000Z","GroundName":"M. A. Chidambaram Stadium","Team":1,"Club":0,"ManOfMatch":19017,"ManOfMatchName":"Priyansh Arya","Team1":1005,"Team2":1011,"GroundId":301,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Chennai Super Kings","Team2Name":"Punjab Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"PBKS won by 5 wickets (with 8 balls remaining)","CityName":"Chennai","CountryName":"India","Innings":[{"MatchNo":9944,"Innings":1,"Score":209,"Overs":20,"Byes":1,"LByes":0,"Wides":15,"NoBalls":1,"BattingTeam":1005,"BowlingTeam":1011,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-29T09:24:49.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9944,"Innings":2,"Score":210,"Overs":18.4,"Byes":0,"LByes":1,"Wides":6,"NoBalls":2,"BattingTeam":1011,"BowlingTeam":1005,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-29T09:24:49.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9906,"Season":"2025-26","Dated":"2026-04-02T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":6283,"ManOfMatchName":"Azam Khan","Team1":998,"Team2":1003,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Karachi Kings","Team2Name":"Rawalpindi Pindiz","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kings won by 5 wickets (with 4 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9906,"Innings":1,"Score":197,"Overs":20,"Byes":1,"LByes":8,"Wides":5,"NoBalls":1,"BattingTeam":998,"BowlingTeam":1003,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-04T18:52:06.000Z","BattingTeamName":"Karachi Kings","BowlingTeamName":"Rawalpindi Pindiz","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9906,"Innings":2,"Score":199,"Overs":19.2,"Byes":0,"LByes":1,"Wides":4,"NoBalls":2,"BattingTeam":1003,"BowlingTeam":998,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-04T18:52:06.000Z","BattingTeamName":"Rawalpindi Pindiz","BowlingTeamName":"Karachi Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":11,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage12Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9943,"Season":"2025-26","Dated":"2026-04-02T19:00:00.000Z","GroundName":"Eden Gardens","Team":1,"Club":0,"ManOfMatch":18986,"ManOfMatchName":"Nitish Kumar Reddy","Team1":1013,"Team2":1008,"GroundId":304,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sunrisers Hyderabad","Team2Name":"Kolkata Knight Riders","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"SRH won by 65 runs","CityName":"Kolkata","CountryName":"India","Innings":[{"MatchNo":9943,"Innings":1,"Score":226,"Overs":20,"Byes":0,"LByes":4,"Wides":9,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1008,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-29T09:22:02.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9943,"Innings":2,"Score":161,"Overs":16,"Byes":0,"LByes":1,"Wides":7,"NoBalls":0,"BattingTeam":1008,"BowlingTeam":1013,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-29T09:22:02.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9904,"Season":"2025-26","Dated":"2026-04-02T14:30:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":86,"ManOfMatchName":"Shadab Khan","Team1":997,"Team2":1002,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":null,"TournamentGroup":null,"Team1Name":"Islamabad United","Team2Name":"Quetta Gladiators","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"United won by 8 wickets (with 10 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9904,"Innings":1,"Score":183,"Overs":20,"Byes":0,"LByes":0,"Wides":4,"NoBalls":0,"BattingTeam":997,"BowlingTeam":1002,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-04T18:45:38.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Quetta Gladiators","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9904,"Innings":2,"Score":189,"Overs":18.2,"Byes":0,"LByes":7,"Wides":11,"NoBalls":0,"BattingTeam":1002,"BowlingTeam":997,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-05-04T18:45:38.000Z","BattingTeamName":"Quetta Gladiators","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9903,"Season":"2025-26","Dated":"2026-04-01T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":6768,"ManOfMatchName":"Sahibzada Farhan","Team1":996,"Team2":1000,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Hyderabad Kingsmen","Team2Name":"Multan Sultan","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Sultans won by 6 wickets (with 8 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9903,"Innings":1,"Score":225,"Overs":20,"Byes":0,"LByes":0,"Wides":5,"NoBalls":2,"BattingTeam":996,"BowlingTeam":1000,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-04T18:45:40.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9903,"Innings":2,"Score":227,"Overs":18.4,"Byes":0,"LByes":0,"Wides":6,"NoBalls":1,"BattingTeam":1000,"BowlingTeam":996,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-04T18:45:40.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9942,"Season":"2025-26","Dated":"2026-04-01T19:00:00.000Z","GroundName":"Bharat Ratna Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19041,"ManOfMatchName":"Sameer Rizvi","Team1":1009,"Team2":1006,"GroundId":314,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lucknow Super Giants","Team2Name":"Delhi Capitals","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"DC won by 6 wickets (with 17 balls remaining)","CityName":"Lucknow","CountryName":"India","Innings":[{"MatchNo":9942,"Innings":1,"Score":141,"Overs":18.4,"Byes":4,"LByes":8,"Wides":2,"NoBalls":0,"BattingTeam":1009,"BowlingTeam":1006,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-28T18:36:07.000Z","BattingTeamName":"Lucknow Super Giants","BowlingTeamName":"Delhi Capitals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9942,"Innings":2,"Score":145,"Overs":17.1,"Byes":0,"LByes":4,"Wides":16,"NoBalls":0,"BattingTeam":1006,"BowlingTeam":1009,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-28T18:36:07.000Z","BattingTeamName":"Delhi Capitals","BowlingTeamName":"Lucknow Super Giants","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9902,"Season":"2025-26","Dated":"2026-03-31T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":997,"Team2":1001,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Islamabad United","Team2Name":"Peshawar Zalmi","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Match abandoned without a ball bowled","CityName":"Lahore","CountryName":"Pakistan","Innings":[]},{"MatchNo":9941,"Season":"2025-26","Dated":"2026-03-31T19:00:00.000Z","GroundName":"Maharaja Yadavindra Singh Cricket Stadium","Team":1,"Club":0,"ManOfMatch":18820,"ManOfMatchName":"Cooper Connolly","Team1":1007,"Team2":1011,"GroundId":315,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Gujarat Titans","Team2Name":"Punjab Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"PBKS won by 3 wickets (with 5 balls remaining)","CityName":"New Chandigarh","CountryName":"India","Innings":[{"MatchNo":9941,"Innings":1,"Score":162,"Overs":20,"Byes":0,"LByes":2,"Wides":11,"NoBalls":1,"BattingTeam":1007,"BowlingTeam":1011,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-28T16:40:20.000Z","BattingTeamName":"Gujarat Titans","BowlingTeamName":"Punjab Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9941,"Innings":2,"Score":165,"Overs":19.1,"Byes":0,"LByes":0,"Wides":4,"NoBalls":0,"BattingTeam":1011,"BowlingTeam":1007,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-05-28T16:40:20.000Z","BattingTeamName":"Punjab Kings","BowlingTeamName":"Gujarat Titans","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9940,"Season":"2025-26","Dated":"2026-03-30T19:00:00.000Z","GroundName":"Barsapara Cricket Stadium","Team":1,"Club":0,"ManOfMatch":19025,"ManOfMatchName":"Nandre Burger","Team1":1012,"Team2":1005,"GroundId":311,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rajasthan Royals","Team2Name":"Chennai Super Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RR won by 8 wickets (with 47 balls remaining)","CityName":"Guwahati","CountryName":"India","Innings":[{"MatchNo":9940,"Innings":1,"Score":127,"Overs":19.4,"Byes":0,"LByes":9,"Wides":6,"NoBalls":1,"BattingTeam":1012,"BowlingTeam":1005,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-28T18:21:32.000Z","BattingTeamName":"Rajasthan Royals","BowlingTeamName":"Chennai Super Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9940,"Innings":2,"Score":128,"Overs":12.1,"Byes":4,"LByes":1,"Wides":1,"NoBalls":0,"BattingTeam":1005,"BowlingTeam":1012,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-05-28T18:21:32.000Z","BattingTeamName":"Chennai Super Kings","BowlingTeamName":"Rajasthan Royals","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9901,"Season":"2025-26","Dated":"2026-03-29T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18818,"ManOfMatchName":"Adam Zampa","Team1":999,"Team2":998,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Lahore Qalandars","Team2Name":"Karachi Kings","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kings won by 4 wickets (with 3 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9901,"Innings":1,"Score":128,"Overs":20,"Byes":0,"LByes":3,"Wides":4,"NoBalls":2,"BattingTeam":999,"BowlingTeam":998,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-05-04T18:38:23.000Z","BattingTeamName":"Lahore Qalandars","BowlingTeamName":"Karachi Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9901,"Innings":2,"Score":131,"Overs":19.3,"Byes":0,"LByes":1,"Wides":4,"NoBalls":1,"BattingTeam":998,"BowlingTeam":999,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-04T18:38:23.000Z","BattingTeamName":"Karachi Kings","BowlingTeamName":"Lahore Qalandars","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9939,"Season":"2025-26","Dated":"2026-03-29T19:00:00.000Z","GroundName":"Wankhede Stadium","Team":1,"Club":0,"ManOfMatch":19000,"ManOfMatchName":"Shardul Thakur","Team1":1010,"Team2":1008,"GroundId":303,"TournamentId":193,"RoundId":76,"GroupId":0,"TournamentGroup":null,"Team1Name":"Mumbai Indians","Team2Name":"Kolkata Knight Riders","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"MI won by 6 wickets (with 5 balls remaining)","CityName":"Mumbai","CountryName":"India","Innings":[{"MatchNo":9939,"Innings":1,"Score":220,"Overs":20,"Byes":0,"LByes":2,"Wides":7,"NoBalls":1,"BattingTeam":1008,"BowlingTeam":1010,"Wickets":4,"UpdateBy":19,"UpdateTime":"2026-05-28T13:51:47.000Z","BattingTeamName":"Kolkata Knight Riders","BowlingTeamName":"Mumbai Indians","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9939,"Innings":2,"Score":224,"Overs":19.1,"Byes":0,"LByes":2,"Wides":3,"NoBalls":1,"BattingTeam":1010,"BowlingTeam":1008,"Wickets":4,"UpdateBy":19,"UpdateTime":"2026-05-28T13:51:40.000Z","BattingTeamName":"Mumbai Indians","BowlingTeamName":"Kolkata Knight Riders","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9899,"Season":"2025-26","Dated":"2026-03-29T14:30:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18942,"ManOfMatchName":"Shamyl Hussain","Team1":996,"Team2":1002,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":null,"TournamentGroup":null,"Team1Name":"Hyderabad Kingsmen","Team2Name":"Quetta Gladiators","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Gladiators won by 40 runs","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9899,"Innings":1,"Score":174,"Overs":20,"Byes":1,"LByes":1,"Wides":4,"NoBalls":5,"BattingTeam":996,"BowlingTeam":1002,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-03T11:53:05.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Quetta Gladiators","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9899,"Innings":2,"Score":134,"Overs":20,"Byes":1,"LByes":1,"Wides":5,"NoBalls":0,"BattingTeam":1002,"BowlingTeam":996,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-03T11:53:05.000Z","BattingTeamName":"Quetta Gladiators","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":12,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage13Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9898,"Season":"2025-26","Dated":"2026-03-28T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18952,"ManOfMatchName":"Momin Qamar","Team1":997,"Team2":1000,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":null,"TournamentGroup":null,"Team1Name":"Islamabad United","Team2Name":"Multan Sultan","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Sultans won by 5 wickets (with 8 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9898,"Innings":1,"Score":171,"Overs":20,"Byes":0,"LByes":6,"Wides":6,"NoBalls":0,"BattingTeam":997,"BowlingTeam":1000,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-05-03T11:52:34.000Z","BattingTeamName":"Islamabad United","BowlingTeamName":"Multan Sultan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9898,"Innings":2,"Score":175,"Overs":18.4,"Byes":2,"LByes":1,"Wides":3,"NoBalls":0,"BattingTeam":1000,"BowlingTeam":997,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-03T11:52:34.000Z","BattingTeamName":"Multan Sultan","BowlingTeamName":"Islamabad United","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9938,"Season":"2025-26","Dated":"2026-03-28T19:00:00.000Z","GroundName":"M Chinnaswamy Stadium","Team":1,"Club":0,"ManOfMatch":18696,"ManOfMatchName":"Jacob Duffy","Team1":1004,"Team2":1013,"GroundId":310,"TournamentId":193,"RoundId":76,"GroupId":null,"TournamentGroup":null,"Team1Name":"Royal Challengers Bengaluru","Team2Name":"Sunrisers Hyderabad","Type":"Tournament","Format":"T20","Level":"","Tournament":"Indian Premier League 2026","Live":"","Official":"Official","ResultDetail":"RCB won by 6 wickets (with 26 balls remaining)","CityName":"Bangaluru","CountryName":"India","Innings":[{"MatchNo":9938,"Innings":1,"Score":201,"Overs":20,"Byes":0,"LByes":2,"Wides":4,"NoBalls":0,"BattingTeam":1013,"BowlingTeam":1004,"Wickets":9,"UpdateBy":19,"UpdateTime":"2026-05-28T12:50:39.000Z","BattingTeamName":"Sunrisers Hyderabad","BowlingTeamName":"Royal Challengers Bengaluru","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9938,"Innings":2,"Score":203,"Overs":15.4,"Byes":8,"LByes":3,"Wides":7,"NoBalls":0,"BattingTeam":1004,"BowlingTeam":1013,"Wickets":4,"UpdateBy":19,"UpdateTime":"2026-05-28T12:51:00.000Z","BattingTeamName":"Royal Challengers Bengaluru","BowlingTeamName":"Sunrisers Hyderabad","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9897,"Season":"2025-26","Dated":"2026-03-28T18:30:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18932,"ManOfMatchName":"Michael Bracewell","Team1":1003,"Team2":1001,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":0,"TournamentGroup":null,"Team1Name":"Rawalpindi Pindiz","Team2Name":"Peshawar Zalmi","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Zalmi won by 5 wickets (with 5 balls remaining)","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9897,"Innings":1,"Score":214,"Overs":20,"Byes":0,"LByes":1,"Wides":5,"NoBalls":1,"BattingTeam":1003,"BowlingTeam":1001,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-05-03T11:47:55.000Z","BattingTeamName":"Rawalpindi Pindiz","BowlingTeamName":"Peshawar Zalmi","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9897,"Innings":2,"Score":218,"Overs":19.1,"Byes":0,"LByes":1,"Wides":6,"NoBalls":1,"BattingTeam":1001,"BowlingTeam":1003,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-05-03T11:47:55.000Z","BattingTeamName":"Peshawar Zalmi","BowlingTeamName":"Rawalpindi Pindiz","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9896,"Season":"2025-26","Dated":"2026-03-27T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":18420,"ManOfMatchName":"Moeen Ali ","Team1":998,"Team2":1002,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":null,"TournamentGroup":null,"Team1Name":"Karachi Kings","Team2Name":"Quetta Gladiators","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Kings won by 14 runs","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9896,"Innings":1,"Score":181,"Overs":20,"Byes":0,"LByes":4,"Wides":1,"NoBalls":0,"BattingTeam":998,"BowlingTeam":1002,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-05-02T14:14:16.000Z","BattingTeamName":"Karachi Kings","BowlingTeamName":"Quetta Gladiators","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9896,"Innings":2,"Score":167,"Overs":20,"Byes":0,"LByes":1,"Wides":2,"NoBalls":0,"BattingTeam":1002,"BowlingTeam":998,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-05-02T14:14:16.000Z","BattingTeamName":"Quetta Gladiators","BowlingTeamName":"Karachi Kings","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9894,"Season":"2025-26","Dated":"2026-03-26T19:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team":1,"Club":0,"ManOfMatch":3398,"ManOfMatchName":"Fakhar Zaman","Team1":999,"Team2":996,"GroundId":116,"TournamentId":192,"RoundId":74,"GroupId":null,"TournamentGroup":null,"Team1Name":"Lahore Qalandars","Team2Name":"Hyderabad Kingsmen","Type":"Tournament","Format":"T20","Level":"","Tournament":"Pakistan Super League 2026","Live":"","Official":"Official","ResultDetail":"Qalanders won by 69 runs","CityName":"Lahore","CountryName":"Pakistan","Innings":[{"MatchNo":9894,"Innings":1,"Score":199,"Overs":20,"Byes":1,"LByes":4,"Wides":6,"NoBalls":2,"BattingTeam":999,"BowlingTeam":996,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-05-02T11:53:11.000Z","BattingTeamName":"Lahore Qalandars","BowlingTeamName":"Hyderabad Kingsmen","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9894,"Innings":2,"Score":130,"Overs":20,"Byes":0,"LByes":7,"Wides":3,"NoBalls":1,"BattingTeam":996,"BowlingTeam":999,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-05-02T11:53:11.000Z","BattingTeamName":"Hyderabad Kingsmen","BowlingTeamName":"Lahore Qalandars","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9893,"Season":"2025-26","Dated":"2026-03-08T10:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":980,"Team2":986,"GroundId":300,"TournamentId":191,"RoundId":72,"GroupId":null,"TournamentGroup":null,"Team1Name":"India","Team2Name":"New Zealand","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"Live","Official":"Official","ResultDetail":"India won by 96 runs","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9893,"Innings":1,"Score":255,"Overs":20,"Byes":0,"LByes":0,"Wides":8,"NoBalls":0,"BattingTeam":980,"BowlingTeam":986,"Wickets":5,"UpdateBy":19,"UpdateTime":"2026-05-25T18:44:31.000Z","BattingTeamName":"India","BowlingTeamName":"New Zealand","MatchType":"T","CurrentStrikePlayerId":18669,"ballsInCurrentOver":0,"CurrentNonStrikePlayerId":18672,"CurrentBowlerPlayerId":18693},{"MatchNo":9893,"Innings":2,"Score":159,"Overs":19,"Byes":4,"LByes":1,"Wides":7,"NoBalls":0,"BattingTeam":986,"BowlingTeam":980,"Wickets":10,"UpdateBy":19,"UpdateTime":"2026-05-25T18:46:52.000Z","BattingTeamName":"New Zealand","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":18696,"ballsInCurrentOver":0,"CurrentNonStrikePlayerId":18698,"CurrentBowlerPlayerId":18663}]},{"MatchNo":9892,"Season":"2025-26","Dated":"2026-03-05T10:00:00.000Z","GroundName":"Wankhede Stadium","Team":1,"Club":0,"ManOfMatch":18841,"ManOfMatchName":"Sanju Samson","Team1":980,"Team2":979,"GroundId":303,"TournamentId":191,"RoundId":71,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"England","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"India won by 7 runs","CityName":"Mumbai","CountryName":"India","Innings":[{"MatchNo":9892,"Innings":1,"Score":253,"Overs":20,"Byes":2,"LByes":1,"Wides":9,"NoBalls":0,"BattingTeam":980,"BowlingTeam":979,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-03-12T06:44:54.000Z","BattingTeamName":"India","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9892,"Innings":2,"Score":246,"Overs":20,"Byes":0,"LByes":3,"Wides":10,"NoBalls":0,"BattingTeam":979,"BowlingTeam":980,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-03-12T06:44:54.000Z","BattingTeamName":"England","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9891,"Season":"2025-26","Dated":"2026-03-04T10:00:00.000Z","GroundName":"Eden Gardens","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":990,"Team2":986,"GroundId":304,"TournamentId":191,"RoundId":71,"GroupId":0,"TournamentGroup":null,"Team1Name":"South Africa","Team2Name":"New Zealand","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"New Zealand won by 9 wickets (with 43 balls remaining)","CityName":"Kolkata","CountryName":"India","Innings":[{"MatchNo":9891,"Innings":1,"Score":169,"Overs":20,"Byes":0,"LByes":1,"Wides":12,"NoBalls":1,"BattingTeam":990,"BowlingTeam":986,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-03-12T06:41:05.000Z","BattingTeamName":"South Africa","BowlingTeamName":"New Zealand","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9891,"Innings":2,"Score":173,"Overs":12.5,"Byes":0,"LByes":2,"Wides":0,"NoBalls":0,"BattingTeam":986,"BowlingTeam":990,"Wickets":1,"UpdateBy":1,"UpdateTime":"2026-03-12T06:41:05.000Z","BattingTeamName":"New Zealand","BowlingTeamName":"South Africa","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9889,"Season":"2025-26","Dated":"2026-03-01T10:00:00.000Z","GroundName":"Arun Jaitley Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":995,"Team2":990,"GroundId":302,"TournamentId":191,"RoundId":70,"GroupId":0,"TournamentGroup":null,"Team1Name":"Zimbabwe","Team2Name":"South Africa","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"South Africa won by 5 wickets (with 13 balls remaining)","CityName":"New Delhi","CountryName":"India","Innings":[{"MatchNo":9889,"Innings":1,"Score":153,"Overs":20,"Byes":0,"LByes":1,"Wides":3,"NoBalls":1,"BattingTeam":995,"BowlingTeam":990,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-03-12T06:29:25.000Z","BattingTeamName":"Zimbabwe","BowlingTeamName":"South Africa","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9889,"Innings":2,"Score":154,"Overs":17.5,"Byes":0,"LByes":0,"Wides":3,"NoBalls":1,"BattingTeam":990,"BowlingTeam":995,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-03-12T06:29:25.000Z","BattingTeamName":"South Africa","BowlingTeamName":"Zimbabwe","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9890,"Season":"2025-26","Dated":"2026-03-01T10:00:00.000Z","GroundName":"Eden Gardens","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":980,"Team2":994,"GroundId":304,"TournamentId":191,"RoundId":70,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"West Indies","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"India won by 5 wickets (with 4 balls remaining)","CityName":"Kolkata","CountryName":"India","Innings":[{"MatchNo":9890,"Innings":1,"Score":195,"Overs":20,"Byes":0,"LByes":1,"Wides":10,"NoBalls":0,"BattingTeam":980,"BowlingTeam":994,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-03-12T06:33:55.000Z","BattingTeamName":"India","BowlingTeamName":"West Indies","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9890,"Innings":2,"Score":199,"Overs":19.2,"Byes":0,"LByes":5,"Wides":7,"NoBalls":0,"BattingTeam":994,"BowlingTeam":980,"Wickets":5,"UpdateBy":1,"UpdateTime":"2026-03-12T06:33:55.000Z","BattingTeamName":"West Indies","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":13,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage14Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9888,"Season":"2025-26","Dated":"2026-02-28T10:00:00.000Z","GroundName":"Pallekele International Cricket Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":988,"Team2":991,"GroundId":307,"TournamentId":191,"RoundId":73,"GroupId":0,"TournamentGroup":null,"Team1Name":"Pakistan","Team2Name":"Sri Lanka","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"Pakistan won by 5 runs","CityName":"Kandy","CountryName":"Sri Lanka","Innings":[{"MatchNo":9888,"Innings":1,"Score":212,"Overs":20,"Byes":0,"LByes":3,"Wides":3,"NoBalls":0,"BattingTeam":988,"BowlingTeam":991,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-03-12T06:15:52.000Z","BattingTeamName":"Pakistan","BowlingTeamName":"Sri Lanka","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9888,"Innings":2,"Score":207,"Overs":20,"Byes":0,"LByes":3,"Wides":6,"NoBalls":0,"BattingTeam":991,"BowlingTeam":988,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-03-12T06:15:52.000Z","BattingTeamName":"Sri Lanka","BowlingTeamName":"Pakistan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9887,"Season":"2025-26","Dated":"2026-02-27T10:00:00.000Z","GroundName":"Colombo (RSP) ","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":986,"Team2":979,"GroundId":309,"TournamentId":191,"RoundId":73,"GroupId":0,"TournamentGroup":null,"Team1Name":"New Zealand","Team2Name":"England","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"England won by 4 wickets (with 3 balls remaining)","CityName":"Colombo","CountryName":"Sri Lanka","Innings":[{"MatchNo":9887,"Innings":1,"Score":159,"Overs":20,"Byes":0,"LByes":1,"Wides":2,"NoBalls":0,"BattingTeam":986,"BowlingTeam":979,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-03-12T06:14:59.000Z","BattingTeamName":"New Zealand","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9887,"Innings":2,"Score":161,"Overs":19.3,"Byes":0,"LByes":3,"Wides":1,"NoBalls":0,"BattingTeam":979,"BowlingTeam":986,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-03-12T06:14:59.000Z","BattingTeamName":"England","BowlingTeamName":"New Zealand","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9885,"Season":"2025-26","Dated":"2026-02-26T10:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":994,"Team2":990,"GroundId":300,"TournamentId":191,"RoundId":70,"GroupId":0,"TournamentGroup":null,"Team1Name":"West Indies","Team2Name":"South Africa","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"South Africa won by 9 wickets (with 23 balls remaining)","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9885,"Innings":1,"Score":176,"Overs":20,"Byes":0,"LByes":0,"Wides":2,"NoBalls":0,"BattingTeam":994,"BowlingTeam":990,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-03-12T06:12:34.000Z","BattingTeamName":"West Indies","BowlingTeamName":"South Africa","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9885,"Innings":2,"Score":177,"Overs":16.1,"Byes":0,"LByes":0,"Wides":2,"NoBalls":1,"BattingTeam":990,"BowlingTeam":994,"Wickets":1,"UpdateBy":1,"UpdateTime":"2026-03-12T06:12:34.000Z","BattingTeamName":"South Africa","BowlingTeamName":"West Indies","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9886,"Season":"2025-26","Dated":"2026-02-26T10:00:00.000Z","GroundName":"M. A. Chidambaram Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":980,"Team2":995,"GroundId":301,"TournamentId":191,"RoundId":70,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"Zimbabwe","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"India won by 72 runs","CityName":"Chennai","CountryName":"India","Innings":[{"MatchNo":9886,"Innings":1,"Score":256,"Overs":20,"Byes":0,"LByes":4,"Wides":7,"NoBalls":1,"BattingTeam":980,"BowlingTeam":995,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-03-12T06:14:14.000Z","BattingTeamName":"India","BowlingTeamName":"Zimbabwe","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9886,"Innings":2,"Score":184,"Overs":20,"Byes":1,"LByes":1,"Wides":7,"NoBalls":2,"BattingTeam":995,"BowlingTeam":980,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-03-12T06:14:14.000Z","BattingTeamName":"Zimbabwe","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9884,"Season":"2025-26","Dated":"2026-02-25T10:00:00.000Z","GroundName":"Colombo (RSP) ","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":986,"Team2":991,"GroundId":309,"TournamentId":191,"RoundId":73,"GroupId":0,"TournamentGroup":null,"Team1Name":"New Zealand","Team2Name":"Sri Lanka","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"New Zealand won by 61 runs","CityName":"Colombo","CountryName":"Sri Lanka","Innings":[{"MatchNo":9884,"Innings":1,"Score":168,"Overs":20,"Byes":0,"LByes":1,"Wides":5,"NoBalls":0,"BattingTeam":986,"BowlingTeam":991,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-03-12T06:10:44.000Z","BattingTeamName":"New Zealand","BowlingTeamName":"Sri Lanka","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9884,"Innings":2,"Score":107,"Overs":20,"Byes":1,"LByes":1,"Wides":5,"NoBalls":0,"BattingTeam":991,"BowlingTeam":986,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-03-12T06:10:44.000Z","BattingTeamName":"Sri Lanka","BowlingTeamName":"New Zealand","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9883,"Season":"2025-26","Dated":"2026-02-24T10:00:00.000Z","GroundName":"Pallekele International Cricket Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":988,"Team2":979,"GroundId":307,"TournamentId":191,"RoundId":73,"GroupId":0,"TournamentGroup":null,"Team1Name":"Pakistan","Team2Name":"England","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"England won by 2 wickets (with 5 balls remaining)","CityName":"Kandy","CountryName":"Sri Lanka","Innings":[{"MatchNo":9883,"Innings":1,"Score":164,"Overs":20,"Byes":0,"LByes":0,"Wides":3,"NoBalls":1,"BattingTeam":988,"BowlingTeam":979,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-03-12T06:09:03.000Z","BattingTeamName":"Pakistan","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9883,"Innings":2,"Score":166,"Overs":19.1,"Byes":0,"LByes":1,"Wides":3,"NoBalls":0,"BattingTeam":979,"BowlingTeam":988,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-03-12T06:09:03.000Z","BattingTeamName":"England","BowlingTeamName":"Pakistan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9882,"Season":"2025-26","Dated":"2026-02-23T10:00:00.000Z","GroundName":"Wankhede Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":994,"Team2":995,"GroundId":303,"TournamentId":191,"RoundId":70,"GroupId":0,"TournamentGroup":null,"Team1Name":"West Indies","Team2Name":"Zimbabwe","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"West Indies won by 107 runs","CityName":"Mumbai","CountryName":"India","Innings":[{"MatchNo":9882,"Innings":1,"Score":254,"Overs":20,"Byes":0,"LByes":10,"Wides":10,"NoBalls":1,"BattingTeam":994,"BowlingTeam":995,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-03-12T06:07:41.000Z","BattingTeamName":"West Indies","BowlingTeamName":"Zimbabwe","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9882,"Innings":2,"Score":147,"Overs":17.4,"Byes":0,"LByes":4,"Wides":5,"NoBalls":0,"BattingTeam":995,"BowlingTeam":994,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-03-12T06:07:41.000Z","BattingTeamName":"Zimbabwe","BowlingTeamName":"West Indies","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9880,"Season":"2025-26","Dated":"2026-02-22T10:00:00.000Z","GroundName":"Pallekele International Cricket Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":979,"Team2":991,"GroundId":307,"TournamentId":191,"RoundId":73,"GroupId":0,"TournamentGroup":null,"Team1Name":"England","Team2Name":"Sri Lanka","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"England won by 51 runs","CityName":"Kandy","CountryName":"Sri Lanka","Innings":[{"MatchNo":9880,"Innings":1,"Score":146,"Overs":20,"Byes":0,"LByes":2,"Wides":3,"NoBalls":0,"BattingTeam":979,"BowlingTeam":991,"Wickets":9,"UpdateBy":1,"UpdateTime":"2026-03-12T06:03:11.000Z","BattingTeamName":"England","BowlingTeamName":"Sri Lanka","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9880,"Innings":2,"Score":95,"Overs":16.4,"Byes":0,"LByes":0,"Wides":2,"NoBalls":0,"BattingTeam":991,"BowlingTeam":979,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-03-12T06:03:11.000Z","BattingTeamName":"Sri Lanka","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9881,"Season":"2025-26","Dated":"2026-02-22T10:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":990,"Team2":980,"GroundId":300,"TournamentId":191,"RoundId":70,"GroupId":null,"TournamentGroup":null,"Team1Name":"South Africa","Team2Name":"India","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"South Africa won by 76 runs","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9881,"Innings":1,"Score":187,"Overs":20,"Byes":1,"LByes":2,"Wides":6,"NoBalls":2,"BattingTeam":990,"BowlingTeam":980,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-03-12T06:05:39.000Z","BattingTeamName":"South Africa","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9881,"Innings":2,"Score":111,"Overs":18.5,"Byes":0,"LByes":1,"Wides":4,"NoBalls":0,"BattingTeam":980,"BowlingTeam":990,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-03-12T06:05:39.000Z","BattingTeamName":"India","BowlingTeamName":"South Africa","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9879,"Season":"2025-26","Dated":"2026-02-21T10:00:00.000Z","GroundName":"Colombo (RSP) ","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":988,"Team2":986,"GroundId":309,"TournamentId":191,"RoundId":73,"GroupId":0,"TournamentGroup":null,"Team1Name":"Pakistan","Team2Name":"New Zealand","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"No result (abandoned with a toss)","CityName":"Colombo","CountryName":"Sri Lanka","Innings":[]}],"pagination":{"current_page":14,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

const String _rawResultsPage15Json = r'''
{"status":true,"message":"All results retrieved successfully","received_data":{"matches":[{"MatchNo":9878,"Season":"2025-26","Dated":"2026-02-20T10:00:00.000Z","GroundName":"Pallekele International Cricket Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":977,"Team2":987,"GroundId":307,"TournamentId":191,"RoundId":67,"GroupId":0,"TournamentGroup":null,"Team1Name":"Australia","Team2Name":"Oman","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"Australia won by 9 wickets (with 62 balls remaining)","CityName":"Kandy","CountryName":"Sri Lanka","Innings":[{"MatchNo":9878,"Innings":1,"Score":104,"Overs":16.2,"Byes":0,"LByes":2,"Wides":6,"NoBalls":0,"BattingTeam":977,"BowlingTeam":987,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-03-11T17:51:07.000Z","BattingTeamName":"Australia","BowlingTeamName":"Oman","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9878,"Innings":2,"Score":108,"Overs":9.4,"Byes":0,"LByes":0,"Wides":0,"NoBalls":0,"BattingTeam":987,"BowlingTeam":977,"Wickets":1,"UpdateBy":1,"UpdateTime":"2026-03-11T17:51:07.000Z","BattingTeamName":"Oman","BowlingTeamName":"Australia","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9875,"Season":"2025-26","Dated":"2026-02-19T10:00:00.000Z","GroundName":"Eden Gardens","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":982,"Team2":994,"GroundId":304,"TournamentId":191,"RoundId":68,"GroupId":0,"TournamentGroup":null,"Team1Name":"Italy","Team2Name":"West Indies","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"West Indies won by 42 runs","CityName":"Kolkata","CountryName":"India","Innings":[{"MatchNo":9875,"Innings":1,"Score":165,"Overs":20,"Byes":0,"LByes":0,"Wides":3,"NoBalls":0,"BattingTeam":994,"BowlingTeam":982,"Wickets":6,"UpdateBy":19,"UpdateTime":"2026-05-02T17:40:29.000Z","BattingTeamName":"West Indies","BowlingTeamName":"Italy","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9875,"Innings":2,"Score":123,"Overs":18,"Byes":0,"LByes":6,"Wides":9,"NoBalls":0,"BattingTeam":982,"BowlingTeam":994,"Wickets":10,"UpdateBy":19,"UpdateTime":"2026-05-02T17:40:36.000Z","BattingTeamName":"Italy","BowlingTeamName":"West Indies","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9876,"Season":"2025-26","Dated":"2026-02-19T10:00:00.000Z","GroundName":"Colombo (RSP) ","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":991,"Team2":995,"GroundId":309,"TournamentId":191,"RoundId":67,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sri Lanka","Team2Name":"Zimbabwe","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"Zimbabwe won by 6 wickets (with 3 balls remaining)","CityName":"Colombo","CountryName":"Sri Lanka","Innings":[{"MatchNo":9876,"Innings":1,"Score":178,"Overs":20,"Byes":0,"LByes":3,"Wides":4,"NoBalls":1,"BattingTeam":991,"BowlingTeam":995,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-03-11T17:49:02.000Z","BattingTeamName":"Sri Lanka","BowlingTeamName":"Zimbabwe","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9876,"Innings":2,"Score":182,"Overs":19.3,"Byes":0,"LByes":3,"Wides":5,"NoBalls":0,"BattingTeam":995,"BowlingTeam":991,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-03-11T17:49:02.000Z","BattingTeamName":"Zimbabwe","BowlingTeamName":"Sri Lanka","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9877,"Season":"2025-26","Dated":"2026-02-19T10:00:00.000Z","GroundName":"M. A. Chidambaram Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":976,"Team2":978,"GroundId":301,"TournamentId":191,"RoundId":69,"GroupId":0,"TournamentGroup":null,"Team1Name":"Afghanistan","Team2Name":"Canada","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"Afghanistan won by 82 runs","CityName":"Chennai","CountryName":"India","Innings":[{"MatchNo":9877,"Innings":1,"Score":200,"Overs":20,"Byes":6,"LByes":1,"Wides":5,"NoBalls":1,"BattingTeam":976,"BowlingTeam":978,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-03-11T17:49:53.000Z","BattingTeamName":"Afghanistan","BowlingTeamName":"Canada","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9877,"Innings":2,"Score":118,"Overs":20,"Byes":0,"LByes":5,"Wides":1,"NoBalls":0,"BattingTeam":978,"BowlingTeam":976,"Wickets":8,"UpdateBy":1,"UpdateTime":"2026-03-11T17:49:53.000Z","BattingTeamName":"Canada","BowlingTeamName":"Afghanistan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9872,"Season":"2025-26","Dated":"2026-02-18T10:00:00.000Z","GroundName":"Arun Jaitley Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":992,"Team2":990,"GroundId":302,"TournamentId":191,"RoundId":69,"GroupId":0,"TournamentGroup":null,"Team1Name":"United Arab Emirates","Team2Name":"South Africa","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"South Africa won by 6 wickets (with 40 balls remaining)","CityName":"New Delhi","CountryName":"India","Innings":[{"MatchNo":9872,"Innings":1,"Score":122,"Overs":20,"Byes":1,"LByes":4,"Wides":8,"NoBalls":0,"BattingTeam":992,"BowlingTeam":990,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-03-11T17:15:07.000Z","BattingTeamName":"United Arab Emirates","BowlingTeamName":"South Africa","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9872,"Innings":2,"Score":123,"Overs":13.2,"Byes":4,"LByes":0,"Wides":2,"NoBalls":0,"BattingTeam":990,"BowlingTeam":992,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-03-11T17:15:07.000Z","BattingTeamName":"South Africa","BowlingTeamName":"United Arab Emirates","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9873,"Season":"2025-26","Dated":"2026-02-18T10:00:00.000Z","GroundName":"Colombo (SSC) ","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":988,"Team2":983,"GroundId":308,"TournamentId":191,"RoundId":66,"GroupId":0,"TournamentGroup":null,"Team1Name":"Pakistan","Team2Name":"Namibia","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"Pakistan won by 102 runs","CityName":"Colombo","CountryName":"Sri Lanka","Innings":[{"MatchNo":9873,"Innings":1,"Score":199,"Overs":20,"Byes":0,"LByes":2,"Wides":4,"NoBalls":0,"BattingTeam":988,"BowlingTeam":983,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-03-11T17:22:41.000Z","BattingTeamName":"Pakistan","BowlingTeamName":"Namibia","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9873,"Innings":2,"Score":97,"Overs":17.3,"Byes":0,"LByes":3,"Wides":4,"NoBalls":0,"BattingTeam":983,"BowlingTeam":988,"Wickets":10,"UpdateBy":1,"UpdateTime":"2026-03-11T17:22:41.000Z","BattingTeamName":"Namibia","BowlingTeamName":"Pakistan","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9874,"Season":"2025-26","Dated":"2026-02-18T10:00:00.000Z","GroundName":"Narendra Modi Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":980,"Team2":985,"GroundId":300,"TournamentId":191,"RoundId":66,"GroupId":0,"TournamentGroup":null,"Team1Name":"India","Team2Name":"Netherlands","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"India won by 17 runs","CityName":"Ahmedabad","CountryName":"India","Innings":[{"MatchNo":9880,"Innings":1,"Score":193,"Overs":20,"Byes":1,"LByes":0,"Wides":7,"NoBalls":0,"BattingTeam":980,"BowlingTeam":985,"Wickets":6,"UpdateBy":1,"UpdateTime":"2026-03-11T17:24:00.000Z","BattingTeamName":"India","BowlingTeamName":"Netherlands","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9874,"Innings":2,"Score":176,"Overs":20,"Byes":0,"LByes":2,"Wides":4,"NoBalls":0,"BattingTeam":985,"BowlingTeam":980,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-03-11T17:24:00.000Z","BattingTeamName":"Netherlands","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9869,"Season":"2025-26","Dated":"2026-02-17T10:00:00.000Z","GroundName":"M. A. Chidambaram Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":978,"Team2":986,"GroundId":301,"TournamentId":191,"RoundId":69,"GroupId":0,"TournamentGroup":null,"Team1Name":"Canada","Team2Name":"New Zealand","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"New Zealand won by 8 wickets (with 29 balls remaining)","CityName":"Chennai","CountryName":"India","Innings":[{"MatchNo":9869,"Innings":1,"Score":173,"Overs":20,"Byes":0,"LByes":1,"Wides":3,"NoBalls":0,"BattingTeam":978,"BowlingTeam":986,"Wickets":4,"UpdateBy":1,"UpdateTime":"2026-03-11T17:11:29.000Z","BattingTeamName":"Canada","BowlingTeamName":"New Zealand","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9869,"Innings":2,"Score":176,"Overs":15.1,"Byes":0,"LByes":1,"Wides":11,"NoBalls":2,"BattingTeam":986,"BowlingTeam":978,"Wickets":2,"UpdateBy":1,"UpdateTime":"2026-03-11T17:11:29.000Z","BattingTeamName":"New Zealand","BowlingTeamName":"Canada","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]},{"MatchNo":9870,"Season":"2025-26","Dated":"2026-02-17T10:00:00.000Z","GroundName":"Pallekele International Cricket Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":981,"Team2":995,"GroundId":307,"TournamentId":191,"RoundId":67,"GroupId":0,"TournamentGroup":null,"Team1Name":"Ireland","Team2Name":"Zimbabwe","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"Match abandoned without a ball bowled","CityName":"Kandy","CountryName":"Sri Lanka","Innings":[]},{"MatchNo":9871,"Season":"2025-26","Dated":"2026-02-17T10:00:00.000Z","GroundName":"Wankhede Stadium","Team":1,"Club":0,"ManOfMatch":0,"ManOfMatchName":null,"Team1":989,"Team2":984,"GroundId":303,"TournamentId":191,"RoundId":68,"GroupId":0,"TournamentGroup":null,"Team1Name":"Scotland","Team2Name":"Nepal","Type":"Tournament","Format":"T20","Level":"","Tournament":"ICC Men T20 World Cup 2026","Live":"","Official":"Official","ResultDetail":"Nepal won by 7 wickets (with 4 balls remaining)","CityName":"Mumbai","CountryName":"India","Innings":[{"MatchNo":9871,"Innings":1,"Score":170,"Overs":20,"Byes":4,"LByes":6,"Wides":3,"NoBalls":0,"BattingTeam":989,"BowlingTeam":984,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-03-11T17:12:49.000Z","BattingTeamName":"Scotland","BowlingTeamName":"Nepal","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null},{"MatchNo":9871,"Innings":2,"Score":171,"Overs":19.2,"Byes":0,"LByes":3,"Wides":2,"NoBalls":0,"BattingTeam":984,"BowlingTeam":989,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-03-11T17:12:49.000Z","BattingTeamName":"Nepal","BowlingTeamName":"Scotland","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null}]}],"pagination":{"current_page":15,"per_page":10,"total_items":8957,"total_pages":896}}}
''';

String _getFallbackResultsJsonForPage(int page) {
  final mappedPage = page > 0 ? ((page - 1) % 15) + 1 : 1;
  switch (mappedPage) {
    case 1:
      return _rawResultsPage1Json;
    case 2:
      return _rawResultsPage2Json;
    case 3:
      return _rawResultsPage3Json;
    case 4:
      return _rawResultsPage4Json;
    case 5:
      return _rawResultsPage5Json;
    case 6:
      return _rawResultsPage6Json;
    case 7:
      return _rawResultsPage7Json;
    case 8:
      return _rawResultsPage8Json;
    case 9:
      return _rawResultsPage9Json;
    case 10:
      return _rawResultsPage10Json;
    case 11:
      return _rawResultsPage11Json;
    case 12:
      return _rawResultsPage12Json;
    case 13:
      return _rawResultsPage13Json;
    case 14:
      return _rawResultsPage14Json;
    case 15:
      return _rawResultsPage15Json;
    default:
      return _rawResultsPage1Json;
  }
}

const String _rawScorecard10019Json = r'''
{"status":true,"message":"Matches ","received_data":[{"MatchNo":10019,"Season":"2025-26","Dated":"2026-07-19T13:30:00.000Z","Winner":1015,"ResultDetail":"England won by 27 runs","Overs":50,"Team1":1014,"Team2":1015,"ScoreCard":1,"TournamentId":195,"Toss":null,"GroundId":325,"Status":"P","Commentary":0,"City":70,"CountryCode":44,"Type":"Tournament","Official":1,"Format":"One Day","Level":"","Stage":"International","MatchLevel":"","Umpires":"","Refree":"","Scorer":"","RoundId":82,"TournamentGroup":null,"ResultType":"WinLoss","LiveType":"","ICCRecognised":0,"ICCEvent":0,"ManOfMatch":18706,"Team":1,"Club":0,"Team1Name":"India","Team2Name":"England","WinnerName":null,"RunnerUpName":null,"Innings":[{"MatchNo":10019,"Innings":1,"Score":387,"Overs":50,"Byes":0,"LByes":9,"Wides":16,"NoBalls":1,"BattingTeam":1015,"BowlingTeam":1014,"Wickets":3,"UpdateBy":1,"UpdateTime":"2026-07-19T18:24:09.000Z","BattingTeamName":"England","BowlingTeamName":"India","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null,"BattingDetail":[{"MatchNo":10019,"Innings":1,"PlayerId":8200,"Runs":141,"BallsFaced":135,"Fours":18,"Sixes":1,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":0,"HowOut":"Caught","OutDetail":"c & b Prince Yadav","Bowler":19047,"Fielder":19047,"Position":1,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Ben Duckett","FielderName":"Prince Yadav","BowlerName":"Prince Yadav","TeamId":1015,"TeamName":"England","MatchType":"T","FullName":"Ben Duckett","ShortName":"Ben D","PlayingRole":"Wicket Keeper","BattingStyle":"Left Hand Bat","BowlingStyle":"Right Arm Offbreak"},{"MatchNo":10019,"Innings":1,"PlayerId":18706,"Runs":91,"BallsFaced":93,"Fours":11,"Sixes":2,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":0,"HowOut":"Caught","OutDetail":"c Sharma b Prasidh Krishna","Bowler":19011,"Fielder":18999,"Position":2,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Jacob Bethell","FielderName":"Rohit Sharma","BowlerName":"Prasidh Krishna","TeamId":1015,"TeamName":"England","MatchType":"T","FullName":"Jacob Bethell","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":1,"PlayerId":19129,"Runs":74,"BallsFaced":48,"Fours":9,"Sixes":0,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":1,"HowOut":"Not Out","OutDetail":"Not Out","Bowler":null,"Fielder":null,"Position":3,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Joe Root","FielderName":null,"BowlerName":null,"TeamId":1015,"TeamName":"England","MatchType":"T","FullName":"Joe Root","ShortName":"J.Root","PlayingRole":"Batsman","BattingStyle":"Right Hand Bat","BowlingStyle":"Right Arm Offbreak"},{"MatchNo":10019,"Innings":1,"PlayerId":18596,"Runs":14,"BallsFaced":12,"Fours":0,"Sixes":0,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":0,"HowOut":"Caught","OutDetail":"c Kohli b Prasidh Krishna","Bowler":19011,"Fielder":18995,"Position":4,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Harry Brook","FielderName":"Virat Kohli","BowlerName":"Prasidh Krishna","TeamId":1015,"TeamName":"England","MatchType":"T","FullName":" Harry Brook ","ShortName":"HB","PlayingRole":"Allrounder","BattingStyle":"Right Hand Batsman","BowlingStyle":" "},{"MatchNo":10019,"Innings":1,"PlayerId":18707,"Runs":41,"BallsFaced":13,"Fours":4,"Sixes":3,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":1,"HowOut":"Not Out","OutDetail":"Not Out","Bowler":null,"Fielder":null,"Position":5,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Jos Buttler","FielderName":null,"BowlerName":null,"TeamId":1015,"TeamName":"England","MatchType":"T","FullName":"Jos Buttler","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""}],"BowlingDetail":[{"MatchNo":10019,"Innings":1,"PlayerId":18663,"Overs":10,"Maiden":0,"Runs":72,"Wickets":0,"Wides":2,"NoBalls":0,"TeamId":1014,"TeamName":"India","Position":1,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Arshdeep Singh","MatchType":"T","Balls":null,"FullName":"Arshdeep Singh","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":1,"PlayerId":19011,"Overs":10,"Maiden":2,"Runs":69,"Wickets":2,"Wides":1,"NoBalls":0,"TeamId":1014,"TeamName":"India","Position":2,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Prasidh Krishna","MatchType":"T","Balls":null,"FullName":"Prasidh Krishna","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":1,"PlayerId":19047,"Overs":10,"Maiden":0,"Runs":79,"Wickets":1,"Wides":7,"NoBalls":0,"TeamId":1014,"TeamName":"India","Position":3,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Prince Yadav","MatchType":"T","Balls":null,"FullName":"Prince Yadav","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":1,"PlayerId":19128,"Overs":10,"Maiden":0,"Runs":97,"Wickets":0,"Wides":1,"NoBalls":1,"TeamId":1014,"TeamName":"India","Position":4,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Gurnoor Brar","MatchType":"T","Balls":null,"FullName":"Gurnoor Brar","ShortName":"G.Brar","PlayingRole":"Bowler","BattingStyle":"Left Hand Bat","BowlingStyle":"Right Arm Fast"},{"MatchNo":10019,"Innings":1,"PlayerId":18664,"Overs":10,"Maiden":0,"Runs":61,"Wickets":0,"Wides":0,"NoBalls":0,"TeamId":1014,"TeamName":"India","Position":5,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Axar Patel","MatchType":"T","Balls":null,"FullName":"Axar Patel","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""}],"FOW":[{"MatchNo":10019,"Innings":1,"Wicket":1,"Overs":30.1,"Score":192,"Bowler":null,"Batsman":18706,"BatsmanRuns":0,"NewBatsman":null,"Fielder":null,"HowOut":null,"OutDetail":null,"BatsmanName":"Jacob Bethell","NewBatsmanName":null,"FielderName":null,"BowlerName":null,"Balls":null},{"MatchNo":10019,"Innings":1,"Wicket":2,"Overs":43.3,"Score":293,"Bowler":null,"Batsman":8200,"BatsmanRuns":0,"NewBatsman":null,"Fielder":null,"HowOut":null,"OutDetail":null,"BatsmanName":"Ben Duckett","NewBatsmanName":null,"FielderName":null,"BowlerName":null,"Balls":null},{"MatchNo":10019,"Innings":1,"Wicket":3,"Overs":46.5,"Score":324,"Bowler":null,"Batsman":18596,"BatsmanRuns":0,"NewBatsman":null,"Fielder":null,"HowOut":null,"OutDetail":null,"BatsmanName":"Harry Brook","NewBatsmanName":null,"FielderName":null,"BowlerName":null,"Balls":null}]},{"MatchNo":10019,"Innings":2,"Score":360,"Overs":50,"Byes":1,"LByes":3,"Wides":6,"NoBalls":0,"BattingTeam":1014,"BowlingTeam":1015,"Wickets":7,"UpdateBy":1,"UpdateTime":"2026-07-19T18:24:09.000Z","BattingTeamName":"India","BowlingTeamName":"England","MatchType":"T","CurrentStrikePlayerId":null,"ballsInCurrentOver":null,"CurrentNonStrikePlayerId":null,"CurrentBowlerPlayerId":null,"BattingDetail":[{"MatchNo":10019,"Innings":2,"PlayerId":18999,"Runs":138,"BallsFaced":110,"Fours":17,"Sixes":5,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":0,"HowOut":"Bowled","OutDetail":"b Bethell","Bowler":18706,"Fielder":null,"Position":1,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Rohit Sharma","FielderName":null,"BowlerName":"Jacob Bethell","TeamId":1014,"TeamName":"India","MatchType":"T","FullName":"Rohit Sharma","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":2,"PlayerId":19014,"Runs":77,"BallsFaced":84,"Fours":10,"Sixes":1,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":0,"HowOut":"LBW","OutDetail":"lbw b Rashid","Bowler":18705,"Fielder":null,"Position":2,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Shubman Gill","FielderName":null,"BowlerName":"Adil Rashid","TeamId":1014,"TeamName":"India","MatchType":"T","FullName":"Shubman Gill","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":2,"PlayerId":18995,"Runs":74,"BallsFaced":60,"Fours":4,"Sixes":3,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":0,"HowOut":"Caught","OutDetail":"c Brook b Curran","Bowler":18709,"Fielder":18596,"Position":3,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Virat Kohli","FielderName":"Harry Brook","BowlerName":"Sam Curran","TeamId":1014,"TeamName":"India","MatchType":"T","FullName":"Virat Kohli","ShortName":"","PlayingRole":"Batsman","BattingStyle":"Right Hand Bat","BowlingStyle":"Right Arm Offbreak"},{"MatchNo":10019,"Innings":2,"PlayerId":18666,"Runs":14,"BallsFaced":12,"Fours":1,"Sixes":0,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":0,"HowOut":"Caught","OutDetail":"c sub (Rehan Ahmed) b Curran","Bowler":18709,"Fielder":19132,"Position":4,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Ishan Kishan","FielderName":"sub (Rehan Ahmed)","BowlerName":"Sam Curran","TeamId":1014,"TeamName":"India","MatchType":"T","FullName":"Ishan Kishan","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":2,"PlayerId":19019,"Runs":0,"BallsFaced":3,"Fours":0,"Sixes":0,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":0,"HowOut":"Caught","OutDetail":"c sub (Rehan Ahmed) b Curran","Bowler":18709,"Fielder":19132,"Position":5,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Shreyas Iyer","FielderName":"sub (Rehan Ahmed)","BowlerName":"Sam Curran","TeamId":1014,"TeamName":"India","MatchType":"T","FullName":"Shreyas Iyer","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":2,"PlayerId":19038,"Runs":12,"BallsFaced":8,"Fours":2,"Sixes":0,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":0,"HowOut":"Bowled","OutDetail":"b Archer","Bowler":13890,"Fielder":null,"Position":6,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"KL Rahul","FielderName":null,"BowlerName":"Jofra Archer","TeamId":1014,"TeamName":"India","MatchType":"T","FullName":"KL Rahul","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":2,"PlayerId":18664,"Runs":2,"BallsFaced":3,"Fours":0,"Sixes":0,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":0,"HowOut":"Caught","OutDetail":"c Jacks b Curran","Bowler":18709,"Fielder":18614,"Position":7,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Axar Patel","FielderName":"Will Jacks","BowlerName":"Sam Curran","TeamId":1014,"TeamName":"India","MatchType":"T","FullName":"Axar Patel","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":2,"PlayerId":19128,"Runs":18,"BallsFaced":14,"Fours":1,"Sixes":1,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":1,"HowOut":"Not Out","OutDetail":"Not Out","Bowler":null,"Fielder":null,"Position":8,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Gurnoor Brar","FielderName":null,"BowlerName":null,"TeamId":1014,"TeamName":"India","MatchType":"T","FullName":"Gurnoor Brar","ShortName":"G.Brar","PlayingRole":"Bowler","BattingStyle":"Left Hand Bat","BowlingStyle":"Right Arm Fast"},{"MatchNo":10019,"Innings":2,"PlayerId":18663,"Runs":15,"BallsFaced":6,"Fours":3,"Sixes":0,"Singles":0,"Doubles":0,"Threes":0,"Dots":0,"NotOut":1,"HowOut":"Not Out","OutDetail":"Not Out","Bowler":null,"Fielder":null,"Position":9,"UpdateBy":1,"LastUpdated":"2026-07-19T18:24:09.000Z","BatsmanName":"Arshdeep Singh","FielderName":null,"BowlerName":null,"TeamId":1014,"TeamName":"India","MatchType":"T","FullName":"Arshdeep Singh","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""}],"BowlingDetail":[{"MatchNo":10019,"Innings":2,"PlayerId":13890,"Overs":10,"Maiden":0,"Runs":63,"Wickets":1,"Wides":0,"NoBalls":0,"TeamId":1015,"TeamName":"England","Position":1,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Jofra Archer","MatchType":"T","Balls":null,"FullName":"Jofra Archer","ShortName":"Jofra A","PlayingRole":"Bowler","BattingStyle":"Right Hand Batsman","BowlingStyle":"Right Arm Medium"},{"MatchNo":10019,"Innings":2,"PlayerId":19130,"Overs":6,"Maiden":0,"Runs":24,"Wickets":0,"Wides":0,"NoBalls":0,"TeamId":1015,"TeamName":"England","Position":2,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Gus Atkinson","MatchType":"T","Balls":null,"FullName":"Gus Atkinson","ShortName":"G.Atkinson","PlayingRole":"Bowler","BattingStyle":"Right Hand Bat","BowlingStyle":"Right Arm Fast"},{"MatchNo":10019,"Innings":2,"PlayerId":18907,"Overs":5,"Maiden":1,"Runs":43,"Wickets":0,"Wides":1,"NoBalls":0,"TeamId":1015,"TeamName":"England","Position":3,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Josh Tongue","MatchType":"T","Balls":null,"FullName":"Josh Tongue","ShortName":"J.Tongue","PlayingRole":"Bowler","BattingStyle":"Right Hand Bat","BowlingStyle":"Right Arm Fast"},{"MatchNo":10019,"Innings":2,"PlayerId":18709,"Overs":10,"Maiden":0,"Runs":75,"Wickets":4,"Wides":1,"NoBalls":0,"TeamId":1015,"TeamName":"England","Position":4,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Sam Curran","MatchType":"T","Balls":null,"FullName":"Sam Curran","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":2,"PlayerId":18705,"Overs":8,"Maiden":0,"Runs":64,"Wickets":1,"Wides":2,"NoBalls":0,"TeamId":1015,"TeamName":"England","Position":5,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Adil Rashid","MatchType":"T","Balls":null,"FullName":"Adil Rashid","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""},{"MatchNo":10019,"Innings":2,"PlayerId":18614,"Overs":4,"Maiden":0,"Runs":38,"Wickets":0,"Wides":0,"NoBalls":0,"TeamId":1015,"TeamName":"England","Position":6,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Will Jacks","MatchType":"T","Balls":null,"FullName":"Will Jacks","ShortName":"","PlayingRole":"Batsman","BattingStyle":"Right Hand Batsman","BowlingStyle":"Right Arm Offbreak"},{"MatchNo":10019,"Innings":2,"PlayerId":18706,"Overs":7,"Maiden":0,"Runs":49,"Wickets":1,"Wides":1,"NoBalls":0,"TeamId":1015,"TeamName":"England","Position":7,"Current":0,"UpdateBy":1,"LastUpdate":"2026-07-19T18:24:09.000Z","BowlerName":"Jacob Bethell","MatchType":"T","Balls":null,"FullName":"Jacob Bethell","ShortName":"","PlayingRole":"","BattingStyle":"","BowlingStyle":""}],"FOW":[{"MatchNo":10019,"Innings":2,"Wicket":1,"Overs":24.2,"Score":147,"Bowler":null,"Batsman":19014,"BatsmanRuns":0,"NewBatsman":null,"Fielder":null,"HowOut":null,"OutDetail":null,"BatsmanName":"Shubman Gill","NewBatsmanName":null,"FielderName":null,"BowlerName":null,"Balls":null},{"MatchNo":10019,"Innings":2,"Wicket":2,"Overs":38.4,"Score":260,"Bowler":null,"Batsman":18999,"BatsmanRuns":0,"NewBatsman":null,"Fielder":null,"HowOut":null,"OutDetail":null,"BatsmanName":"Rohit Sharma","NewBatsmanName":null,"FielderName":null,"BowlerName":null,"Balls":null},{"MatchNo":10019,"Innings":2,"Wicket":3,"Overs":43.3,"Score":304,"Bowler":null,"Batsman":18666,"BatsmanRuns":0,"NewBatsman":null,"Fielder":null,"HowOut":null,"OutDetail":null,"BatsmanName":"Ishan Kishan","NewBatsmanName":null,"FielderName":null,"BowlerName":null,"Balls":null},{"MatchNo":10019,"Innings":2,"Wicket":4,"Overs":43.6,"Score":304,"Bowler":null,"Batsman":19019,"BatsmanRuns":0,"NewBatsman":null,"Fielder":null,"HowOut":null,"OutDetail":null,"BatsmanName":"Shreyas Iyer","NewBatsmanName":null,"FielderName":null,"BowlerName":null,"Balls":null},{"MatchNo":10019,"Innings":2,"Wicket":5,"Overs":45.2,"Score":315,"Bowler":null,"Batsman":18995,"BatsmanRuns":0,"NewBatsman":null,"Fielder":null,"HowOut":null,"OutDetail":null,"BatsmanName":"Virat Kohli","NewBatsmanName":null,"FielderName":null,"BowlerName":null,"Balls":null},{"MatchNo":10019,"Innings":2,"Wicket":6,"Overs":46.3,"Score":327,"Bowler":null,"Batsman":19038,"BatsmanRuns":0,"NewBatsman":null,"Fielder":null,"HowOut":null,"OutDetail":null,"BatsmanName":"KL Rahul","NewBatsmanName":null,"FielderName":null,"BowlerName":null,"Balls":null},{"MatchNo":10019,"Innings":2,"Wicket":7,"Overs":47.2,"Score":329,"Bowler":null,"Batsman":18664,"BatsmanRuns":0,"NewBatsman":null,"Fielder":null,"HowOut":null,"OutDetail":null,"BatsmanName":"Axar Patel","NewBatsmanName":null,"FielderName":null,"BowlerName":null,"Balls":null}]}]}]}
''';

const String _rawScorecard9620Json = r'''
{"status":true,"message":"Matches ","received_data":[{"MatchNo":9620,"Season":"2020-21","Dated":"2021-09-15T10:00:00.000Z","Winner":null,"ResultDetail":null,"Overs":null,"Team1":945,"Team2":942,"ScoreCard":0,"TournamentId":180,"Toss":null,"GroundId":211,"Status":"S","Commentary":0,"City":null,"CountryCode":92,"Type":"Tournament","Official":1,"Format":"T20","Level":"","Stage":"T20","MatchLevel":null,"Umpires":"","Refree":"","Scorer":"","RoundId":54,"TournamentGroup":null,"ResultType":"WinLoss","LiveType":"O","ICCRecognised":0,"ICCEvent":0,"ManOfMatch":null,"Team":1,"Club":0,"Team1Name":"Balochistan","Team2Name":"Khyber Pakhtunkhwa ","WinnerName":null,"RunnerUpName":null,"Innings":[]}]}
''';

const String _rawFixturesPage1Json = r'''
{"status":true,"message":"All fixtures retrieved successfully","received_data":{"matches":[{"MatchNo":9620,"Season":"2020-21","Dated":"2021-09-15T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":945,"Team2":942,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan","Team2Name":"Khyber Pakhtunkhwa ","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9621,"Season":"2020-21","Dated":"2021-09-15T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":943,"Team2":946,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Central Punjab","Team2Name":"Sindh","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9622,"Season":"2020-21","Dated":"2021-09-16T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":945,"Team2":946,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan","Team2Name":"Sindh","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9623,"Season":"2020-21","Dated":"2021-09-16T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":941,"Team2":944,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Southern Punjab","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9625,"Season":"2020-21","Dated":"2021-09-17T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":945,"Team2":943,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan","Team2Name":"Central Punjab","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9624,"Season":"2020-21","Dated":"2021-09-17T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":942,"Team2":944,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pakhtunkhwa ","Team2Name":"Southern Punjab","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9626,"Season":"2020-21","Dated":"2021-09-18T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":942,"Team2":946,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pakhtunkhwa ","Team2Name":"Sindh","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9627,"Season":"2020-21","Dated":"2021-09-18T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":943,"Team2":944,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Central Punjab","Team2Name":"Southern Punjab","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9628,"Season":"2020-21","Dated":"2021-09-19T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":942,"Team2":943,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pakhtunkhwa ","Team2Name":"Central Punjab","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9629,"Season":"2020-21","Dated":"2021-09-19T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":941,"Team2":946,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Sindh","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null}],"pagination":{"current_page":1,"per_page":10,"total_items":74,"total_pages":8}}}
''';

const String _rawFixturesPage2Json = r'''
{"status":true,"message":"All fixtures retrieved successfully","received_data":{"matches":[{"MatchNo":9631,"Season":"2020-21","Dated":"2021-09-20T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":946,"Team2":944,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sindh","Team2Name":"Southern Punjab","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9630,"Season":"2020-21","Dated":"2021-09-20T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":945,"Team2":941,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan","Team2Name":"Northern","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9632,"Season":"2020-21","Dated":"2021-09-21T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":945,"Team2":943,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan","Team2Name":"Central Punjab","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9633,"Season":"2020-21","Dated":"2021-09-21T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":941,"Team2":943,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Central Punjab","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9634,"Season":"2020-21","Dated":"2021-09-22T10:00:00.000Z","GroundName":"Bugti Stadium, Quetta","Team1":941,"Team2":943,"GroundId":211,"TournamentId":180,"RoundId":54,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Central Punjab","Type":"Tournament","Format":"T20","Level":"","Tournament":"Cricket Associations T20 ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9786,"Season":"2020-21","Dated":"2021-10-06T10:00:00.000Z","GroundName":"Ayub National Park, Rawalpindi","Team1":61,"Team2":679,"GroundId":143,"TournamentId":0,"RoundId":0,"GroupId":0,"TournamentGroup":null,"Team1Name":"Kiwi Boys Cricket Club","Team2Name":"Stars ICCA","Type":"Tournament","Format":"T20","Level":"","Tournament":"","Live":"","Official":"UnOfficial","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9687,"Season":"2020-21","Dated":"2021-11-02T10:00:00.000Z","GroundName":"UnKnown ground","Team1":952,"Team2":947,"GroundId":134,"TournamentId":181,"RoundId":56,"GroupId":0,"TournamentGroup":null,"Team1Name":"Sindh","Team2Name":"Northern ","Type":"Tournament","Format":"Three Day","Level":"","Tournament":"Cricket Associations Championship","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9688,"Season":"2020-21","Dated":"2021-11-02T10:00:00.000Z","GroundName":"LCCA Ground, Lahore","Team1":949,"Team2":951,"GroundId":101,"TournamentId":181,"RoundId":56,"GroupId":0,"TournamentGroup":null,"Team1Name":"Central Punjab","Team2Name":"Balochistan ","Type":"Tournament","Format":"Three Day","Level":"","Tournament":"Cricket Associations Championship","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9689,"Season":"2020-21","Dated":"2021-11-02T10:00:00.000Z","GroundName":"UnKnown ground","Team1":948,"Team2":950,"GroundId":134,"TournamentId":181,"RoundId":56,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa","Team2Name":"Southern Punjab","Type":"Tournament","Format":"Three Day","Level":"","Tournament":"Cricket Associations Championship","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9695,"Season":"2020-21","Dated":"2021-11-12T10:00:00.000Z","GroundName":"LCCA Ground, Lahore","Team1":950,"Team2":949,"GroundId":101,"TournamentId":181,"RoundId":56,"GroupId":0,"TournamentGroup":null,"Team1Name":"Southern Punjab","Team2Name":"Central Punjab","Type":"Tournament","Format":"Three Day","Level":"","Tournament":"Cricket Associations Championship","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null}],"pagination":{"current_page":2,"per_page":10,"total_items":74,"total_pages":8}}}
''';

const String _rawFixturesPage3Json = r'''
{"status":true,"message":"All fixtures retrieved successfully","received_data":{"matches":[{"MatchNo":9694,"Season":"2020-21","Dated":"2021-11-12T10:00:00.000Z","GroundName":"UnKnown ground","Team1":947,"Team2":948,"GroundId":134,"TournamentId":181,"RoundId":56,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern ","Team2Name":"Khyber Pukhtunkhwa","Type":"Tournament","Format":"Three Day","Level":"","Tournament":"Cricket Associations Championship","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9693,"Season":"2020-21","Dated":"2021-11-12T10:00:00.000Z","GroundName":"UnKnown ground","Team1":951,"Team2":952,"GroundId":134,"TournamentId":181,"RoundId":56,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Sindh","Type":"Tournament","Format":"Three Day","Level":"","Tournament":"Cricket Associations Championship","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9727,"Season":"2020-21","Dated":"2021-11-19T10:00:00.000Z","GroundName":"UnKnown ground","Team1":956,"Team2":958,"GroundId":134,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Southern Punjab ","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9728,"Season":"2020-21","Dated":"2021-11-19T10:00:00.000Z","GroundName":"LCCA Ground, Lahore","Team1":954,"Team2":955,"GroundId":101,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa","Team2Name":"Central Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9726,"Season":"2020-21","Dated":"2021-11-19T10:00:00.000Z","GroundName":"UnKnown ground","Team1":957,"Team2":953,"GroundId":134,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Northern","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9729,"Season":"2020-21","Dated":"2021-11-21T10:00:00.000Z","GroundName":"UnKnown ground","Team1":957,"Team2":956,"GroundId":134,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Southern Punjab ","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9730,"Season":"2020-21","Dated":"2021-11-21T10:00:00.000Z","GroundName":"UnKnown ground","Team1":954,"Team2":958,"GroundId":134,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9731,"Season":"2020-21","Dated":"2021-11-21T10:00:00.000Z","GroundName":"LCCA Ground, Lahore","Team1":953,"Team2":955,"GroundId":101,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Central Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9792,"Season":"2020-21","Dated":"2021-11-21T10:00:00.000Z","GroundName":"Carriage Factory Ground,Rawalpindi","Team1":61,"Team2":1273,"GroundId":26,"TournamentId":0,"RoundId":0,"GroupId":0,"TournamentGroup":null,"Team1Name":"Kiwi Boys Cricket Club","Team2Name":"Zahid Mansoor Academy","Type":"Friendly","Format":"One Day","Level":"","Tournament":"","Live":"","Official":"UnOfficial","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9733,"Season":"2020-21","Dated":"2021-11-23T10:00:00.000Z","GroundName":"UnKnown ground","Team1":957,"Team2":954,"GroundId":134,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Khyber Pukhtunkhwa","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null}],"pagination":{"current_page":3,"per_page":10,"total_items":74,"total_pages":8}}}
''';

const String _rawFixturesPage4Json = r'''
{"status":true,"message":"All fixtures retrieved successfully","received_data":{"matches":[{"MatchNo":9732,"Season":"2020-21","Dated":"2021-11-23T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":955,"Team2":958,"GroundId":147,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Central Punjab","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9793,"Season":"2020-21","Dated":"2021-11-24T10:00:00.000Z","GroundName":"UnKnown ground","Team1":61,"Team2":2838,"GroundId":134,"TournamentId":0,"RoundId":0,"GroupId":0,"TournamentGroup":null,"Team1Name":"Kiwi Boys Cricket Club","Team2Name":"Al Fathtay Cricket Club ","Type":"Friendly","Format":"One Day","Level":"","Tournament":"","Live":"","Official":"UnOfficial","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9794,"Season":"2020-21","Dated":"2021-11-25T10:00:00.000Z","GroundName":"Chak Shahzad Cricket Ground,Islamabad","Team1":61,"Team2":2839,"GroundId":12,"TournamentId":0,"RoundId":0,"GroupId":0,"TournamentGroup":null,"Team1Name":"Kiwi Boys Cricket Club","Team2Name":"Pak Kashmir Cricket Club ","Type":"Friendly","Format":"One Day","Level":"","Tournament":"","Live":"","Official":"UnOfficial","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9736,"Season":"2020-21","Dated":"2021-11-25T10:00:00.000Z","GroundName":"LCCA Ground, Lahore","Team1":957,"Team2":958,"GroundId":101,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9737,"Season":"2020-21","Dated":"2021-11-25T10:00:00.000Z","GroundName":"UnKnown ground","Team1":955,"Team2":956,"GroundId":134,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Central Punjab","Team2Name":"Southern Punjab ","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9735,"Season":"2020-21","Dated":"2021-11-25T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":954,"Team2":953,"GroundId":147,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa","Team2Name":"Northern","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9740,"Season":"2020-21","Dated":"2021-11-27T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":954,"Team2":956,"GroundId":147,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa","Team2Name":"Southern Punjab ","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9739,"Season":"2020-21","Dated":"2021-11-27T10:00:00.000Z","GroundName":"LCCA Ground, Lahore","Team1":957,"Team2":955,"GroundId":101,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Central Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9738,"Season":"2020-21","Dated":"2021-11-27T10:00:00.000Z","GroundName":"UnKnown ground","Team1":953,"Team2":958,"GroundId":134,"TournamentId":182,"RoundId":58,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Cricket Associations Challenge ","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9795,"Season":"2020-21","Dated":"2021-11-28T10:00:00.000Z","GroundName":"Asghar Mall College Ground,Rawalpindi","Team1":61,"Team2":32,"GroundId":4,"TournamentId":0,"RoundId":0,"GroupId":0,"TournamentGroup":null,"Team1Name":"Kiwi Boys Cricket Club","Team2Name":"Pak Sports Cricket Club","Type":"Friendly","Format":"One Day","Level":"","Tournament":"","Live":"","Official":"UnOfficial","ScorerId":0,"CityName":null,"CountryName":null}],"pagination":{"current_page":4,"per_page":10,"total_items":74,"total_pages":8}}}
''';

const String _rawFixturesPage5Json = r'''
{"status":true,"message":"All fixtures retrieved successfully","received_data":{"matches":[{"MatchNo":9827,"Season":"2020-21","Dated":"2022-01-27T10:00:00.000Z","GroundName":"National Stadium Karachi","Team1":0,"Team2":0,"GroundId":111,"TournamentId":188,"RoundId":63,"GroupId":0,"TournamentGroup":null,"Team1Name":null,"Team2Name":null,"Type":"Tournament","Format":"T20","Level":"","Tournament":"","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9743,"Season":"2020-21","Dated":"2022-02-25T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":936,"Team2":937,"GroundId":147,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa ","Team2Name":"Central Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9742,"Season":"2020-21","Dated":"2022-02-25T10:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team1":939,"Team2":935,"GroundId":116,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Northern","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9741,"Season":"2020-21","Dated":"2022-02-25T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":938,"Team2":940,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Southern Punjab","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9746,"Season":"2020-21","Dated":"2022-02-28T10:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team1":939,"Team2":938,"GroundId":116,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Southern Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9745,"Season":"2020-21","Dated":"2022-02-28T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":935,"Team2":937,"GroundId":147,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Central Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9744,"Season":"2020-21","Dated":"2022-02-28T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":936,"Team2":940,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa ","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9747,"Season":"2020-21","Dated":"2022-03-03T10:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team1":937,"Team2":940,"GroundId":116,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Central Punjab","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9748,"Season":"2020-21","Dated":"2022-03-03T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":939,"Team2":936,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Khyber Pukhtunkhwa ","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9749,"Season":"2020-21","Dated":"2022-03-03T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":935,"Team2":938,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Southern Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null}],"pagination":{"current_page":5,"per_page":10,"total_items":74,"total_pages":8}}}
''';

const String _rawFixturesPage6Json = r'''
{"status":true,"message":"All fixtures retrieved successfully","received_data":{"matches":[{"MatchNo":9750,"Season":"2020-21","Dated":"2022-03-06T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":939,"Team2":940,"GroundId":147,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9751,"Season":"2020-21","Dated":"2022-03-06T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":936,"Team2":935,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa ","Team2Name":"Northern","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9752,"Season":"2020-21","Dated":"2022-03-06T10:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team1":937,"Team2":938,"GroundId":116,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Central Punjab","Team2Name":"Southern Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9754,"Season":"2020-21","Dated":"2022-03-09T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":935,"Team2":940,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9755,"Season":"2020-21","Dated":"2022-03-09T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":939,"Team2":937,"GroundId":147,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Central Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9753,"Season":"2020-21","Dated":"2022-03-09T10:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team1":936,"Team2":938,"GroundId":116,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa ","Team2Name":"Southern Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9757,"Season":"2020-21","Dated":"2022-03-12T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":937,"Team2":938,"GroundId":147,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Central Punjab","Team2Name":"Southern Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9758,"Season":"2020-21","Dated":"2022-03-12T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":939,"Team2":940,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9756,"Season":"2020-21","Dated":"2022-03-12T10:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team1":936,"Team2":935,"GroundId":116,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa ","Team2Name":"Northern","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9760,"Season":"2020-21","Dated":"2022-03-15T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":939,"Team2":938,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Southern Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null}],"pagination":{"current_page":6,"per_page":10,"total_items":74,"total_pages":8}}}
''';

const String _rawFixturesPage7Json = r'''
{"status":true,"message":"All fixtures retrieved successfully","received_data":{"matches":[{"MatchNo":9759,"Season":"2020-21","Dated":"2022-03-15T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":935,"Team2":937,"GroundId":147,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Central Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9761,"Season":"2020-21","Dated":"2022-03-15T10:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team1":936,"Team2":940,"GroundId":116,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa ","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9764,"Season":"2020-21","Dated":"2022-03-18T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":939,"Team2":937,"GroundId":147,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Central Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9762,"Season":"2020-21","Dated":"2022-03-18T10:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team1":935,"Team2":940,"GroundId":116,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9763,"Season":"2020-21","Dated":"2022-03-18T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":936,"Team2":938,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa ","Team2Name":"Southern Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9767,"Season":"2020-21","Dated":"2022-03-21T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":938,"Team2":940,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Southern Punjab","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9766,"Season":"2020-21","Dated":"2022-03-21T10:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team1":936,"Team2":937,"GroundId":116,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Khyber Pukhtunkhwa ","Team2Name":"Central Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9765,"Season":"2020-21","Dated":"2022-03-21T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":939,"Team2":935,"GroundId":147,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Northern","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9768,"Season":"2020-21","Dated":"2022-03-24T10:00:00.000Z","GroundName":"Gaddafi Cricket Stadium, Lahore","Team1":939,"Team2":936,"GroundId":116,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Balochistan ","Team2Name":"Khyber Pukhtunkhwa ","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":9770,"Season":"2020-21","Dated":"2022-03-24T10:00:00.000Z","GroundName":"Iqbal Stadium, Faisalabad","Team1":937,"Team2":940,"GroundId":147,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Central Punjab","Team2Name":"Sindh","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null}],"pagination":{"current_page":7,"per_page":10,"total_items":74,"total_pages":8}}}
''';

const String _rawFixturesPage8Json = r'''
{"status":true,"message":"All fixtures retrieved successfully","received_data":{"matches":[{"MatchNo":9769,"Season":"2020-21","Dated":"2022-03-24T10:00:00.000Z","GroundName":"Multan Cricket Stadium, Multan","Team1":935,"Team2":938,"GroundId":208,"TournamentId":179,"RoundId":59,"GroupId":0,"TournamentGroup":null,"Team1Name":"Northern","Team2Name":"Southern Punjab","Type":"Tournament","Format":"One Day","Level":"","Tournament":"Pakistan Cup 2021/22","Live":"","Official":"Official","ScorerId":0,"CityName":null,"CountryName":null},{"MatchNo":10012,"Season":"2025-26","Dated":"2026-07-01T09:30:00.000Z","GroundName":"Riverside Ground","Team1":1014,"Team2":1015,"GroundId":318,"TournamentId":194,"RoundId":81,"GroupId":null,"TournamentGroup":null,"Team1Name":"India","Team2Name":"England","Type":"Tournament","Format":"T20","Level":"","Tournament":"India tour of England 2026","Live":"","Official":"Official","ScorerId":0,"CityName":"Chesterle street","CountryName":"England"},{"MatchNo":10020,"Season":"2025-26","Dated":"2026-07-25T19:00:00.000Z","GroundName":"Brian Lara Stadium","Team1":1018,"Team2":1019,"GroundId":326,"TournamentId":196,"RoundId":84,"GroupId":0,"TournamentGroup":null,"Team1Name":"Pakistan","Team2Name":"West Indies","Type":"Tournament","Format":"Test","Level":"","Tournament":"Pakistan tour of West Indies 2026","Live":"","Official":"Official","ScorerId":0,"CityName":"Tarouba","CountryName":"West Indies"},{"MatchNo":10021,"Season":"2025-26","Dated":"2026-08-02T19:00:00.000Z","GroundName":"Queen's Park Oval","Team1":1018,"Team2":1019,"GroundId":326,"TournamentId":196,"RoundId":84,"GroupId":0,"TournamentGroup":null,"Team1Name":"Pakistan","Team2Name":"West Indies","Type":"Tournament","Format":"Test","Level":"","Tournament":"Pakistan tour of West Indies 2026","Live":"","Official":"Official","ScorerId":0,"CityName":"Port of Spain","CountryName":"West Indies"}],"pagination":{"current_page":8,"per_page":10,"total_items":74,"total_pages":8}}}
''';

String _getFallbackFixturesJsonForPage(int page) {
  final mappedPage = page > 0 ? ((page - 1) % 8) + 1 : 1;
  switch (mappedPage) {
    case 1:
      return _rawFixturesPage1Json;
    case 2:
      return _rawFixturesPage2Json;
    case 3:
      return _rawFixturesPage3Json;
    case 4:
      return _rawFixturesPage4Json;
    case 5:
      return _rawFixturesPage5Json;
    case 6:
      return _rawFixturesPage6Json;
    case 7:
      return _rawFixturesPage7Json;
    case 8:
      return _rawFixturesPage8Json;
    default:
      return _rawFixturesPage1Json;
  }
}




