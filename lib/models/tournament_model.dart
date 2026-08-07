class TournamentData {
  final int tournamentId;
  final String name;
  final String format;
  final String startDate;
  final String endDate;
  final String season;
  final String status;
  final String? winnerName;
  final String? runnerUpName;
  final String organizerType;
  final String stage;
  final String countryName;
  final int live;

  TournamentData({
    required this.tournamentId,
    required this.name,
    required this.format,
    required this.startDate,
    required this.endDate,
    required this.season,
    required this.status,
    this.winnerName,
    this.runnerUpName,
    required this.organizerType,
    required this.stage,
    required this.countryName,
    required this.live,
  });

  factory TournamentData.fromJson(Map<String, dynamic> json) {
    String? getCleanVal(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          final val = '${json[key]}'.trim();
          if (val.isNotEmpty && val != 'null' && val != '-') return val;
        }
        final lower = key.toLowerCase();
        for (final entry in json.entries) {
          if (entry.key.toLowerCase() == lower && entry.value != null) {
            final val = '${entry.value}'.trim();
            if (val.isNotEmpty && val != 'null' && val != '-') return val;
          }
        }
      }
      return null;
    }

    final winner = getCleanVal([
      'WinnerName', 'Winner', 'winner_name', 'winner',
      'WinnerTeam', 'WinnerTeamName', 'winner_team',
      'Winner_Name', 'Winner_Team', 'Winner_Team_Name'
    ]);

    final runnerUp = getCleanVal([
      'RunnerUpName', 'RunnerUp', 'runner_up_name', 'runner_up',
      'RunnerUpTeam', 'RunnerUpTeamName', 'runnerup_name', 'runnerup',
      'Runner_Up', 'Runner_up_name', 'RunnerUp_Name', 'RunnerUp_Team',
      'RunnerUp_Team_Name', 'Runner_Up_Team'
    ]);

    return TournamentData(
      tournamentId: json['TournamentId'] as int? ?? json['tournament_id'] as int? ?? 0,
      name: (json['Name'] as String? ?? json['name'] as String? ?? '').trim(),
      format: (json['Format'] as String? ?? json['format'] as String? ?? '').trim(),
      startDate: json['StartDate'] as String? ?? json['start_date'] as String? ?? '',
      endDate: json['EndDate'] as String? ?? json['end_date'] as String? ?? '',
      season: json['Season'] as String? ?? json['season'] as String? ?? '',
      status: json['Status'] as String? ?? json['status'] as String? ?? 'A',
      winnerName: winner,
      runnerUpName: runnerUp,
      organizerType: (json['OrganizerType'] as String? ?? json['organizer_type'] as String? ?? '').trim(),
      stage: (json['Stage'] as String? ?? json['stage'] as String? ?? '').trim(),
      countryName: (json['CountryName'] as String? ?? json['country_name'] as String? ?? '').trim(),
      live: json['Live'] as int? ?? json['live'] as int? ?? 0,
    );
  }

  bool get isLive => live == 1 || status == 'L' || status == 'Live';
  bool get isFinished => status == 'F' || status == 'C' || (winnerName != null && winnerName!.isNotEmpty);

  String get formattedCategory {
    final s = stage.toLowerCase();
    final n = name.toLowerCase();
    if (s.contains('t20') || n.contains('premier league') || n.contains('super league') || n.contains('t20 cup')) {
      return 'Leagues';
    }
    if (stage.toLowerCase().contains('international') || organizerType == 'ICC' || countryName.isEmpty) {
      return 'International';
    }
    return 'Domestic';
  }
}
