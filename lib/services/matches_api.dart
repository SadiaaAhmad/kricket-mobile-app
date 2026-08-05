import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kricket_pk/models/match_model.dart';
import 'package:kricket_pk/models/commentary_model.dart';
import 'package:kricket_pk/data/mock_raw_data.dart';

class MatchesApi {
  static const _baseUri = 'https://kricket.pk/backend/api';

  Future<MatchesResponse> getFixtures({int limit = 10, int page = 1}) async {
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

    return _parseMatchesResponseFromRawJson(getFallbackFixturesJsonForPage(page), requestedPage: page);
  }

  Future<MatchesResponse> getResults({int limit = 10, int page = 1}) async {
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
      print('[DEBUG MatchesApi] WARNING: Live commentary returned status ${response.statusCode} or empty list. Using fallback commentary dataset.');
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG MatchesApi] ERROR fetching commentary for Match #$matchNo: $e. Using fallback commentary dataset.');
    }

    return _getFallbackCommentary(matchNo);
  }

  List<CommentaryOverData> _getFallbackCommentary(int matchNo) {
    // Only return cached commentary for match 9959, otherwise return empty list
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
    // Only return cached fallback scorecard if match is explicitly 9620 or 10019
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
}
