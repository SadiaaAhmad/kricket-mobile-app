import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kricket_pk/models/match_model.dart';
import 'package:kricket_pk/models/commentary_model.dart';
import 'package:kricket_pk/data/mock_raw_data.dart';

class MatchesApi {
  static const _baseUri = 'https://kricket.pk/backend/api';
  static final Map<String, MatchesResponse> _pageCache = {};

  Future<MatchesResponse> getFixtures({int limit = 10, int page = 1}) async {
    final cacheKey = 'fixtures_${limit}_$page';
    if (_pageCache.containsKey(cacheKey)) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] CACHE HIT for $cacheKey! Returning ${_pageCache[cacheKey]!.matches.length} fixtures instantly.');
      return _pageCache[cacheKey]!;
    }

    // ignore: avoid_print
    print('[DEBUG MatchesApi] Fetching fixtures from: $_baseUri/getallmatches?status=S&page=$page&per_page=$limit');
    try {
      final uri = Uri.parse('$_baseUri/getallmatches').replace(
        queryParameters: {'status': 'S', 'page': '$page', 'per_page': '$limit'},
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
            final res = MatchesResponse(matches: matches, pagination: pagination);
            _pageCache[cacheKey] = res;
            // ignore: avoid_print
            print('[DEBUG MatchesApi] SUCCESS: Fetched ${matches.length} fixtures (Page ${pagination.currentPage} of ${pagination.totalPages}) from live network API.');
            return res;
          }
        }
      }
      // ignore: avoid_print
      print('[DEBUG MatchesApi] WARNING: Live API returned status ${response.statusCode} or empty list.');
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] ERROR fetching live fixtures: $e.');
    }

    return _parseMatchesResponseFromRawJson(getFallbackFixturesJsonForPage(page), requestedPage: page);
  }

  Future<MatchesResponse> getResults({int limit = 10, int page = 1}) async {
    final cacheKey = 'results_${limit}_$page';
    if (_pageCache.containsKey(cacheKey)) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] CACHE HIT for $cacheKey! Returning ${_pageCache[cacheKey]!.matches.length} results instantly.');
      return _pageCache[cacheKey]!;
    }

    // ignore: avoid_print
    print('[DEBUG MatchesApi] Fetching results from: $_baseUri/getallresults?status=P&page=$page&per_page=$limit');
    try {
      final uri = Uri.parse('$_baseUri/getallresults').replace(
        queryParameters: {'status': 'P', 'page': '$page', 'per_page': '$limit'},
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
            final res = MatchesResponse(matches: matches, pagination: pagination);
            _pageCache[cacheKey] = res;
            // ignore: avoid_print
            print('[DEBUG MatchesApi] SUCCESS: Fetched ${matches.length} results (Page ${pagination.currentPage} of ${pagination.totalPages}) from live network API.');
            return res;
          }
        }
      }
      // ignore: avoid_print
      print('[DEBUG MatchesApi] WARNING: Live API returned status ${response.statusCode} or empty list.');
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] ERROR fetching live results: $e.');
    }

    return _parseMatchesResponseFromRawJson(getFallbackResultsJsonForPage(page), requestedPage: page);
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
            // ignore: avoid_print
            print('[DEBUG MatchesApi] SUCCESS: Fetched ${innings.length} innings for Match #$matchNo.');
            return innings;
          }
        }
      }
      // ignore: avoid_print
      print('[DEBUG MatchesApi] WARNING: Live scorecard returned status ${response.statusCode} or empty innings.');
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] ERROR fetching scorecard: $e');
    }

    return _getFallbackScorecard(matchNo);
  }

  Future<List<CommentaryOverData>> getCommentary(int matchNo) async {
    // ignore: avoid_print
    print('[DEBUG MatchesApi] Fetching commentary for Match #$matchNo from: $_baseUri/commentary/$matchNo');
    try {
      final uri = Uri.parse('$_baseUri/commentary/$matchNo');
      final response = await http.Client().get(uri).timeout(const Duration(seconds: 10));
      // ignore: avoid_print
      print('[DEBUG MatchesApi] Commentary response HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (payload['status'] == true && payload['received_data'] != null) {
          final oversList = (payload['received_data'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .map(CommentaryOverData.fromJson)
                  .toList() ??
              [];
          if (oversList.isNotEmpty) {
            // ignore: avoid_print
            print('[DEBUG MatchesApi] SUCCESS: Fetched ${oversList.length} commentary overs from live network API.');
            return oversList;
          }
        }
      }
      // ignore: avoid_print
      print('[DEBUG MatchesApi] WARNING: Live commentary returned status ${response.statusCode} or empty list.');
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] ERROR fetching commentary for Match #$matchNo: $e.');
    }

    return _getFallbackCommentary(matchNo);
  }

  List<CommentaryOverData> _getFallbackCommentary(int matchNo) {
    if (matchNo == 9959) {
      try {
        final payload = jsonDecode(rawCommentary9959Json) as Map<String, dynamic>;
        final oversList = (payload['received_data'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(CommentaryOverData.fromJson)
                .toList() ??
            [];
        return oversList;
      } catch (_) {}
    }
    return [];
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
      return MatchesResponse(matches: matchesList, pagination: pagination);
    } catch (e) {
      return const MatchesResponse(matches: [], pagination: PaginationData());
    }
  }

  List<InningsData> _getFallbackScorecard(int matchNo) {
    if (matchNo == 9620 || matchNo == 10019) {
      try {
        final String jsonStr = matchNo == 9620 ? rawScorecard9620Json : rawScorecard10019Json;
        final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
        final matchDataList = payload['received_data'] as List<dynamic>?;
        if (matchDataList != null && matchDataList.isNotEmpty) {
          final matchData = matchDataList.first as Map<String, dynamic>;
          final innings = (matchData['Innings'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .map(InningsData.fromJson)
                  .toList() ??
              [];
          return innings;
        }
      } catch (_) {}
    }
    return [];
  }

  /// Fast search for results strictly matching tournamentId or tournamentName across all 75 backend pages
  Future<List<MatchData>> getResultsByTournament(int tournamentId, String tournamentName) async {
    // ignore: avoid_print
    print('[DEBUG MatchesApi] START getResultsByTournament ID: $tournamentId, Name: "$tournamentName"');
    final matches = <MatchData>[];
    final seenMatchNos = <int>{};
    final tName = tournamentName.trim().toLowerCase();

    // Strategy 1: Direct backend endpoints
    final directUris = <Uri>[
      Uri.parse('$_baseUri/getresultsbytournament/$tournamentId'),
      Uri.parse('$_baseUri/getmatchesbytournament/$tournamentId'),
      Uri.parse('$_baseUri/getallresults?status=P&tournament_id=$tournamentId&per_page=100'),
      Uri.parse('$_baseUri/getallresults?status=P&tournament=$tournamentId&per_page=100'),
    ];

    for (final uri in directUris) {
      try {
        // ignore: avoid_print
        print('[DEBUG MatchesApi] Checking direct URI: $uri');
        final response = await http.Client().get(uri).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final payload = jsonDecode(utf8.decode(response.bodyBytes));
          List<dynamic>? rawList;
          if (payload is Map<String, dynamic>) {
            if (payload['received_data'] != null) {
              final rd = payload['received_data'];
              if (rd is List) {
                rawList = rd;
              } else if (rd is Map && rd['matches'] != null) {
                rawList = rd['matches'] as List?;
              }
            }
          } else if (payload is List) {
            rawList = payload;
          }
          if (rawList != null && rawList.isNotEmpty) {
            for (final item in rawList) {
              if (item is Map<String, dynamic>) {
                final m = MatchData.fromJson(item);
                final mTour = m.tournament.trim().toLowerCase();
                bool isMatch = false;
                if (tournamentId > 0 && m.tournamentId == tournamentId) {
                  isMatch = true;
                } else if (tName.isNotEmpty && mTour.isNotEmpty) {
                  if (mTour == tName || (tName.length >= 6 && (mTour == tName || mTour.contains(tName) || tName.contains(mTour)))) {
                    isMatch = true;
                  }
                }
                if (isMatch && seenMatchNos.add(m.matchNo)) {
                  matches.add(m);
                }
              }
            }
            if (matches.isNotEmpty) {
              // ignore: avoid_print
              print('[DEBUG MatchesApi] SUCCESS via Direct URI! Found ${matches.length} results for Tournament $tournamentId.');
              return matches;
            }
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('[DEBUG MatchesApi] Direct URI $uri exception: $e');
      }
    }

    // Strategy 2: Parallel chunk scanning (5 pages per chunk max to prevent socket overload)
    const chunkSize = 5;
    const maxPages = 75;

    for (int startPage = 1; startPage <= maxPages; startPage += chunkSize) {
      try {
        final endPage = (startPage + chunkSize - 1).clamp(1, maxPages);
        // ignore: avoid_print
        print('[DEBUG MatchesApi] Batch scanning chunk pages $startPage..$endPage...');
        final futures = <Future<MatchesResponse>>[];
        for (int p = startPage; p <= endPage; p++) {
          futures.add(getResults(limit: 100, page: p));
        }

        final responses = await Future.wait(futures).timeout(const Duration(seconds: 4));
        for (final res in responses) {
          for (final m in res.matches) {
            if (seenMatchNos.contains(m.matchNo)) continue;
            final mTour = m.tournament.trim().toLowerCase();
            bool isMatch = false;
            if (tournamentId > 0 && m.tournamentId == tournamentId) {
              isMatch = true;
            } else if (tName.isNotEmpty && mTour.isNotEmpty) {
              if (mTour == tName || (tName.length >= 6 && (mTour == tName || mTour.contains(tName) || tName.contains(mTour)))) {
                isMatch = true;
              }
            }
            if (isMatch && seenMatchNos.add(m.matchNo)) {
              matches.add(m);
            }
          }
        }

        if (matches.isNotEmpty) {
          // ignore: avoid_print
          print('[DEBUG MatchesApi] SUCCESS! Found ${matches.length} results in page chunk $startPage..$endPage!');
          break;
        }
      } catch (e) {
        // ignore: avoid_print
        print('[DEBUG MatchesApi] Chunk $startPage.. error: $e');
      }
    }

    return matches;
  }

  /// Fast search for fixtures strictly matching tournamentId or tournamentName
  Future<List<MatchData>> getFixturesByTournament(int tournamentId, String tournamentName) async {
    // ignore: avoid_print
    print('[DEBUG MatchesApi] START getFixturesByTournament ID: $tournamentId, Name: "$tournamentName"');
    final matches = <MatchData>[];
    final seenMatchNos = <int>{};
    final tName = tournamentName.trim().toLowerCase();

    // Strategy 1: Direct backend endpoints
    final directUris = <Uri>[
      Uri.parse('$_baseUri/getmatchesbytournament/$tournamentId'),
      Uri.parse('$_baseUri/getallmatches?status=S&tournament_id=$tournamentId&per_page=100'),
      Uri.parse('$_baseUri/getallmatches?status=S&tournament=$tournamentId&per_page=100'),
    ];

    for (final uri in directUris) {
      try {
        // ignore: avoid_print
        print('[DEBUG MatchesApi] Checking direct URI: $uri');
        final response = await http.Client().get(uri).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final payload = jsonDecode(utf8.decode(response.bodyBytes));
          List<dynamic>? rawList;
          if (payload is Map<String, dynamic>) {
            if (payload['received_data'] != null) {
              final rd = payload['received_data'];
              if (rd is List) {
                rawList = rd;
              } else if (rd is Map && rd['matches'] != null) {
                rawList = rd['matches'] as List?;
              }
            }
          } else if (payload is List) {
            rawList = payload;
          }
          if (rawList != null && rawList.isNotEmpty) {
            for (final item in rawList) {
              if (item is Map<String, dynamic>) {
                final m = MatchData.fromJson(item);
                if (m.status == 'S' || m.status == 'Scheduled') {
                  final mTour = m.tournament.trim().toLowerCase();
                  bool isMatch = false;
                  if (tournamentId > 0 && m.tournamentId == tournamentId) {
                    isMatch = true;
                  } else if (tName.isNotEmpty && mTour.isNotEmpty) {
                    if (mTour == tName || (tName.length >= 6 && (mTour == tName || mTour.contains(tName) || tName.contains(mTour)))) {
                      isMatch = true;
                    }
                  }
                  if (isMatch && seenMatchNos.add(m.matchNo)) {
                    matches.add(m);
                  }
                }
              }
            }
            if (matches.isNotEmpty) {
              // ignore: avoid_print
              print('[DEBUG MatchesApi] SUCCESS via Direct URI! Found ${matches.length} fixtures for Tournament $tournamentId.');
              return matches;
            }
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('[DEBUG MatchesApi] Direct URI $uri exception: $e');
      }
    }

    // Strategy 2: Parallel page scan (5 pages per chunk max to prevent socket overload)
    const chunkSize = 5;
    const maxPages = 30;

    for (int startPage = 1; startPage <= maxPages; startPage += chunkSize) {
      try {
        final endPage = (startPage + chunkSize - 1).clamp(1, maxPages);
        final futures = <Future<MatchesResponse>>[];
        for (int p = startPage; p <= endPage; p++) {
          futures.add(getFixtures(limit: 100, page: p));
        }

        final responses = await Future.wait(futures).timeout(const Duration(seconds: 4));
        for (final res in responses) {
          for (final m in res.matches) {
            if (seenMatchNos.contains(m.matchNo)) continue;
            final mTour = m.tournament.trim().toLowerCase();
            bool isMatch = false;
            if (tournamentId > 0 && m.tournamentId == tournamentId) {
              isMatch = true;
            } else if (tName.isNotEmpty && mTour.isNotEmpty) {
              if (mTour == tName || (tName.length >= 6 && (mTour == tName || mTour.contains(tName) || tName.contains(mTour)))) {
                isMatch = true;
              }
            }
            if (isMatch && seenMatchNos.add(m.matchNo)) {
              matches.add(m);
            }
          }
        }

        if (matches.isNotEmpty) break;
      } catch (e) {
        // ignore: avoid_print
        print('[DEBUG MatchesApi] Fixtures chunk $startPage error: $e');
      }
    }

    return matches;
  }
}
