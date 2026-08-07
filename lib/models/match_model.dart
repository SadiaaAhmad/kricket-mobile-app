import 'package:kricket_pk/models/article_model.dart';

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
        battingTeamName: cleanText(json['BattingTeamName'] as String? ?? ''),
        bowlingTeamName: cleanText(json['BowlingTeamName'] as String? ?? ''),
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
    this.tournamentId = 0,
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
  final int tournamentId;
  final String? manOfMatchName;
  final String? cityName;
  final String? countryName;
  final String? season;
  final List<MatchInningsSummary> inningsSummaries;

  factory MatchData.fromJson(Map<String, dynamic> json) {
    final live = (json['Live'] as String? ?? '').trim();
    final resultDetailRaw = json['ResultDetail'] as String?;
    final resultDetail = resultDetailRaw != null && resultDetailRaw.isNotEmpty ? cleanText(resultDetailRaw) : null;
    
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

    final tIdRaw = json['TournamentId'] ?? json['tournament_id'] ?? json['TournamentID'] ?? json['tournament_Id'] ?? 0;
    final tId = tIdRaw is int ? tIdRaw : int.tryParse('$tIdRaw') ?? 0;

    return MatchData(
      matchNo: json['MatchNo'] as int? ?? 0,
      team1Name: cleanText(json['Team1Name'] as String? ?? 'Team 1'),
      team2Name: cleanText(json['Team2Name'] as String? ?? 'Team 2'),
      date: formatBackendDate(json['Dated'] as String?),
      groundName: cleanText(json['GroundName'] as String? ?? 'TBA Ground'),
      format: cleanText(json['Format'] as String? ?? 'T20'),
      tournament: cleanText(json['Tournament'] as String? ?? 'Cricket Tournament'),
      resultDetail: resultDetail,
      team1: json['Team1'] as int? ?? 0,
      team2: json['Team2'] as int? ?? 0,
      status: status,
      tournamentId: tId,
      manOfMatchName: json['ManOfMatchName'] != null ? cleanText(json['ManOfMatchName'] as String) : null,
      cityName: json['CityName'] != null ? cleanText(json['CityName'] as String) : null,
      countryName: json['CountryName'] != null ? cleanText(json['CountryName'] as String) : null,
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
        batsmanName: cleanText(json['BatsmanName'] as String? ?? 'Batter'),
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
        battingTeamName: cleanText(json['BattingTeamName'] as String? ?? 'Team'),
        bowlingTeamName: cleanText(json['BowlingTeamName'] as String? ?? 'Team'),
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
        batsmanName: cleanText(json['BatsmanName'] as String? ?? 'Unknown'),
        runs: json['Runs'] as int? ?? 0,
        ballsFaced: json['BallsFaced'] as int? ?? 0,
        fours: json['Fours'] as int? ?? 0,
        sixes: json['Sixes'] as int? ?? 0,
        notOut: json['NotOut'] as int? ?? 0,
        howOut: json['HowOut'] as String? ?? 'Not Out',
        bowlerName: json['BowlerName'] != null ? cleanText(json['BowlerName'] as String) : null,
        outDetail: json['OutDetail'] != null ? cleanText(json['OutDetail'] as String) : null,
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
        bowlerName: cleanText(json['BowlerName'] as String? ?? 'Unknown'),
        overs: '${json['Overs'] ?? '0'}',
        maiden: json['Maiden'] as int? ?? 0,
        runs: json['Runs'] as int? ?? 0,
        wickets: json['Wickets'] as int? ?? 0,
        wides: json['Wides'] as int? ?? 0,
        noBalls: json['NoBalls'] as int? ?? 0,
      );
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
