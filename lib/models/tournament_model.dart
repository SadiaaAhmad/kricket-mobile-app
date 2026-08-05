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
    String? runnerUp;
    if (json['RunnerUpName'] != null && (json['RunnerUpName'] as String).trim().isNotEmpty) {
      runnerUp = (json['RunnerUpName'] as String).trim();
    } else if (json['RunnerUp'] != null && json['RunnerUp'] is String && (json['RunnerUp'] as String).trim().isNotEmpty) {
      runnerUp = (json['RunnerUp'] as String).trim();
    }

    return TournamentData(
      tournamentId: json['TournamentId'] as int? ?? 0,
      name: (json['Name'] as String? ?? '').trim(),
      format: (json['Format'] as String? ?? '').trim(),
      startDate: json['StartDate'] as String? ?? '',
      endDate: json['EndDate'] as String? ?? '',
      season: json['Season'] as String? ?? '',
      status: json['Status'] as String? ?? 'A',
      winnerName: json['WinnerName'] != null && (json['WinnerName'] as String).trim().isNotEmpty
          ? (json['WinnerName'] as String).trim()
          : null,
      runnerUpName: runnerUp,
      organizerType: (json['OrganizerType'] as String? ?? '').trim(),
      stage: (json['Stage'] as String? ?? '').trim(),
      countryName: (json['CountryName'] as String? ?? '').trim(),
      live: json['Live'] as int? ?? 0,
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
