class CommentaryBallData {
  const CommentaryBallData({
    required this.ballId,
    required this.matchNo,
    required this.innings,
    required this.over,
    required this.ball,
    required this.runs,
    required this.wide,
    required this.noBall,
    required this.legByes,
    required this.byes,
    required this.wicket,
    required this.batsmanName,
    required this.bowlerName,
    this.ballPitch,
    this.shotArea,
    this.outDetail,
    this.eventType,
    this.comment,
  });

  final int ballId;
  final int matchNo;
  final int innings;
  final int over;
  final int ball;
  final int runs;
  final int wide;
  final int noBall;
  final int legByes;
  final int byes;
  final int wicket;
  final String batsmanName;
  final String bowlerName;
  final String? ballPitch;
  final String? shotArea;
  final String? outDetail;
  final String? eventType;
  final String? comment;

  factory CommentaryBallData.fromJson(Map<String, dynamic> json) {
    return CommentaryBallData(
      ballId: json['BallId'] as int? ?? 0,
      matchNo: json['MatchNo'] as int? ?? 0,
      innings: json['Innings'] as int? ?? 1,
      over: json['Over'] as int? ?? 0,
      ball: json['Ball'] as int? ?? 0,
      runs: json['Runs'] as int? ?? 0,
      wide: json['Wide'] as int? ?? 0,
      noBall: json['NoBall'] as int? ?? 0,
      legByes: json['LegByes'] as int? ?? 0,
      byes: json['Byes'] as int? ?? 0,
      wicket: json['Wicket'] as int? ?? 0,
      batsmanName: (json['BatsmanName'] as String?)?.trim() ?? 'Batsman',
      bowlerName: (json['BowlerName'] as String?)?.trim() ?? 'Bowler',
      ballPitch: json['BallPitch'] as String?,
      shotArea: json['ShotArea'] as String?,
      outDetail: json['OutDetail'] as String?,
      eventType: json['EventType'] as String?,
      comment: json['comment'] as String?,
    );
  }

  bool get isBoundary => runs == 4 || runs == 6;
  bool get isWicket => wicket > 0 || (eventType != null && eventType!.toUpperCase() == 'WICKET');
  bool get isExtra => wide > 0 || noBall > 0 || legByes > 0 || byes > 0;

  String get ballBadgeText {
    if (isWicket) return 'W';
    if (wide > 0) return 'WD';
    if (noBall > 0) return 'NB';
    if (legByes > 0) return '${legByes}LB';
    if (byes > 0) return '${byes}B';
    return '$runs';
  }
}

class CommentaryOverData {
  const CommentaryOverData({
    required this.matchNo,
    required this.innings,
    required this.over,
    required this.score,
    required this.wicket,
    required this.runsInOver,
    required this.wicketsInOver,
    required this.strikerName,
    required this.nonStrikerName,
    required this.bowlerName,
    required this.strikerRuns,
    required this.strikerBalls,
    required this.nonStrikerRuns,
    required this.nonStrikerBalls,
    required this.bowlerRuns,
    required this.bowlerWickets,
    required this.bowlerOver,
    required this.balls,
  });

  final int matchNo;
  final int innings;
  final int over;
  final int score;
  final int wicket;
  final int runsInOver;
  final int wicketsInOver;
  final String strikerName;
  final String nonStrikerName;
  final String bowlerName;
  final int strikerRuns;
  final int strikerBalls;
  final int nonStrikerRuns;
  final int nonStrikerBalls;
  final int bowlerRuns;
  final int bowlerWickets;
  final int bowlerOver;
  final List<CommentaryBallData> balls;

  factory CommentaryOverData.fromJson(Map<String, dynamic> json) {
    final ballsRaw = json['balls'] as List<dynamic>?;
    final parsedBalls = ballsRaw
            ?.cast<Map<String, dynamic>>()
            .map(CommentaryBallData.fromJson)
            .toList() ??
        [];

    return CommentaryOverData(
      matchNo: json['MatchNo'] as int? ?? 0,
      innings: json['Innings'] as int? ?? 1,
      over: json['Over'] as int? ?? 0,
      score: json['Score'] as int? ?? 0,
      wicket: json['Wicket'] as int? ?? 0,
      runsInOver: json['RunsInOver'] as int? ?? 0,
      wicketsInOver: json['WicketsInOver'] as int? ?? 0,
      strikerName: (json['StrikerName'] as String?)?.trim() ?? '',
      nonStrikerName: (json['NonStrikerName'] as String?)?.trim() ?? '',
      bowlerName: (json['BowlerName'] as String?)?.trim() ?? '',
      strikerRuns: json['StrikerRuns'] as int? ?? 0,
      strikerBalls: json['StrikerBalls'] as int? ?? 0,
      nonStrikerRuns: json['NonStrikerRuns'] as int? ?? 0,
      nonStrikerBalls: json['NonStrikerBalls'] as int? ?? 0,
      bowlerRuns: json['BowlerRuns'] as int? ?? 0,
      bowlerWickets: json['BowlerWicket'] as int? ?? 0,
      bowlerOver: json['BowlerOver'] as int? ?? 0,
      balls: parsedBalls,
    );
  }
}
