import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/match_model.dart';

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
                        TeamAvatar(name: match.team1Name),
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
                        TeamAvatar(name: match.team2Name),
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

class TeamAvatar extends StatelessWidget {
  const TeamAvatar({super.key, required this.name, this.size = 36});
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
                    TeamAvatar(name: innings.battingTeamName, size: 22),
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
