import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kricket_pk/data/real_tournaments.dart';
import 'package:kricket_pk/models/tournament_model.dart';
import 'package:kricket_pk/models/article_model.dart';

class TournamentPaginatedResult {
  final List<TournamentData> tournaments;
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;

  TournamentPaginatedResult({
    required this.tournaments,
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });
}

class TournamentsApi {
  static const String baseUrl = 'https://www.kricket.pk/backend/api';

  Future<TournamentPaginatedResult> getTournaments({
    int page = 1,
    int perPage = 10,
    String query = '',
    String category = 'All',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/getalltournaments').replace(
        queryParameters: {'page': '$page', 'per_page': '$perPage'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final payload = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (payload['status'] == true && payload['received_data'] != null) {
          final dataMap = payload['received_data'] as Map<String, dynamic>;
          final rawTournaments = dataMap['tournaments'] as List<dynamic>? ?? [];
          var list = rawTournaments.map((e) => TournamentData.fromJson(e as Map<String, dynamic>)).toList();

          final pag = dataMap['pagination'] as Map<String, dynamic>?;
          final totalItems = pag?['total_items'] as int? ?? 189;
          final totalPages = pag?['total_pages'] as int? ?? 19;
          final currentPage = pag?['current_page'] as int? ?? page;

          if (category != 'All') {
            list = list.where((t) {
              if (category == 'Domestic') {
                return t.formattedCategory == 'Domestic';
              } else if (category == 'International') {
                return t.formattedCategory == 'International';
              } else if (category == 'Leagues') {
                return t.formattedCategory == 'Leagues';
              }
              return true;
            }).toList();
          }

          if (query.trim().isNotEmpty) {
            final q = query.trim().toLowerCase();
            list = list.where((t) =>
              t.name.toLowerCase().contains(q) ||
              t.format.toLowerCase().contains(q) ||
              t.stage.toLowerCase().contains(q) ||
              t.organizerType.toLowerCase().contains(q)
            ).toList();
          }

          return TournamentPaginatedResult(
            tournaments: list,
            currentPage: currentPage,
            perPage: perPage,
            totalItems: totalItems,
            totalPages: totalPages,
          );
        }
      }
    } catch (_) {}

    // Fallback to pre-cached dataset
    var list = getRealTournaments();

    if (category != 'All') {
      list = list.where((t) {
        if (category == 'Domestic') {
          return t.formattedCategory == 'Domestic';
        } else if (category == 'International') {
          return t.formattedCategory == 'International';
        } else if (category == 'Leagues') {
          return t.formattedCategory == 'Leagues';
        }
        return true;
      }).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((t) =>
        t.name.toLowerCase().contains(q) ||
        t.format.toLowerCase().contains(q) ||
        t.stage.toLowerCase().contains(q) ||
        t.organizerType.toLowerCase().contains(q)
      ).toList();
    }

    final totalItems = list.isEmpty ? 189 : list.length;
    final totalPages = (totalItems / perPage).ceil();

    final safePage = page.clamp(1, totalPages > 0 ? totalPages : 1);
    final startIndex = (safePage - 1) * perPage;
    final pageItems = list.skip(startIndex).take(perPage).toList();

    return TournamentPaginatedResult(
      tournaments: pageItems,
      currentPage: safePage,
      perPage: perPage,
      totalItems: totalItems,
      totalPages: totalPages > 0 ? totalPages : 1,
    );
  }

  /// Fetch tournament details by ID
  Future<TournamentData?> getTournamentById(int tournamentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/gettournamentbyid/$tournamentId'));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody['status'] == true && jsonBody['received_data'] != null) {
          return TournamentData.fromJson(jsonBody['received_data']);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch participating teams for a tournament ID
  Future<List<Map<String, dynamic>>> getTournamentTeams(int tournamentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/gettournamentteams/$tournamentId'));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody['status'] == true && jsonBody['received_data'] != null) {
          final List list = jsonBody['received_data'];
          return list.map((item) => item as Map<String, dynamic>).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch squad player list for a team ID
  Future<List<Map<String, dynamic>>> getSquadByTeam(int teamId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getsquadbyteam/$teamId'));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody['status'] == true && jsonBody['received_data'] != null) {
          final List list = jsonBody['received_data'];
          return list.map((item) => item as Map<String, dynamic>).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Resolve team ID (like "428" or "1014") to actual Team Name
  Future<String> resolveTeamName(String rawIdOrName, int tournamentId) async {
    final cleaned = rawIdOrName.trim();
    if (cleaned.isEmpty || cleaned == 'null') return '';
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return cleaned;

    final teamId = int.tryParse(cleaned) ?? 0;

    // 1. Try tournament teams
    try {
      final teams = await getTournamentTeams(tournamentId);
      for (final item in teams) {
        final id = '${item['TeamId'] ?? item['team_id'] ?? item['Team_Id'] ?? item['id'] ?? item['Team'] ?? ''}'.trim();
        final name = '${item['TeamName'] ?? item['team_name'] ?? item['Team_Name'] ?? item['name'] ?? ''}'.trim();
        if (id == cleaned && name.isNotEmpty && !RegExp(r'^\d+$').hasMatch(name)) {
          return name;
        }
      }
    } catch (_) {}

    // 2. Try team by ID endpoint
    try {
      final response = await http.get(Uri.parse('$baseUrl/getteambyid/$teamId')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody['received_data'] != null) {
          final rd = jsonBody['received_data'];
          final name = '${rd['TeamName'] ?? rd['Name'] ?? rd['team_name'] ?? ''}'.trim();
          if (name.isNotEmpty && !RegExp(r'^\d+$').hasMatch(name)) return name;
        }
      }
    } catch (_) {}

    // 3. Try squad by team endpoint
    if (teamId > 0) {
      try {
        final squad = await getSquadByTeam(teamId);
        if (squad.isNotEmpty) {
          final first = squad.first;
          final tName = '${first['TeamName'] ?? first['team_name'] ?? ''}'.trim();
          if (tName.isNotEmpty && !RegExp(r'^\d+$').hasMatch(tName)) return tName;
        }
      } catch (_) {}
    }

    return cleaned;
  }

  /// Fetch tournament batting stats by ID
  Future<List<Map<String, dynamic>>> getBattingStatsByTournament(int tournamentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getbattingbytournament/$tournamentId'));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody['status'] == true && jsonBody['received_data'] != null) {
          final List list = jsonBody['received_data'];
          return list.map((item) => item as Map<String, dynamic>).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch tournament bowling stats by ID
  Future<List<Map<String, dynamic>>> getBowlingStatsByTournament(int tournamentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getbowlingbytournament/$tournamentId'));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody['status'] == true && jsonBody['received_data'] != null) {
          final List list = jsonBody['received_data'];
          return list.map((item) => item as Map<String, dynamic>).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch articles related to tournament by ObjectType=Tournament & ObjectId={tournamentId}
  Future<List<ArticleData>> getArticlesByTournament(int tournamentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getarticlesbyobject?ObjectType=Tournament&ObjectId=$tournamentId'),
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(utf8.decode(response.bodyBytes));
        List<dynamic> list = [];
        if (jsonBody is Map<String, dynamic>) {
          if (jsonBody['status'] == true && jsonBody['received_data'] != null) {
            final rec = jsonBody['received_data'];
            if (rec is List) {
              list = rec;
            } else if (rec is Map<String, dynamic>) {
              list = (rec['articles'] ?? rec['article'] ?? rec['data'] ?? []) as List<dynamic>;
            }
          } else if (jsonBody['data'] is List) {
            list = jsonBody['data'];
          } else if (jsonBody['articles'] is List) {
            list = jsonBody['articles'];
          }
        } else if (jsonBody is List) {
          list = jsonBody;
        }

        return list
            .whereType<Map<String, dynamic>>()
            .map(ArticleData.fromBackendJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
