class PlayerData {
  final int playerId;
  final String fullName;
  final String dob;
  final String battingStyle;
  final String bowlingStyle;
  final String playingRole;
  final String image;
  final String majorTeams;
  final String clubName;
  final String city;
  final String country;

  const PlayerData({
    required this.playerId,
    required this.fullName,
    this.dob = '',
    this.battingStyle = '',
    this.bowlingStyle = '',
    this.playingRole = '',
    this.image = '',
    this.majorTeams = '',
    this.clubName = '',
    this.city = '',
    this.country = '',
  });

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    final id = json['PlayerId'] ?? json['player_id'] ?? json['id'] ?? 0;
    final nameStr = '${json['FullName'] ?? json['full_name'] ?? json['Name'] ?? json['PlayerName'] ?? json['name'] ?? json['RegisteredName'] ?? json['ShortName'] ?? ''}'.trim();
    final dobVal = '${json['DOB'] ?? json['dob'] ?? ''}'.trim();
    final bat = '${json['BattingStyle'] ?? json['batting_style'] ?? ''}'.trim();
    final bowl = '${json['BowlingStyle'] ?? json['bowling_style'] ?? ''}'.trim();
    final role = '${json['PlayingRole'] ?? json['role'] ?? json['Role'] ?? json['PlayingStyle'] ?? ''}'.trim();
    final img = '${json['Image'] ?? json['image'] ?? json['PlayerImage'] ?? ''}'.trim();
    final teams = '${json['MajorTeams'] ?? json['major_teams'] ?? ''}'.trim();
    final club = '${json['ClubName'] ?? json['club_name'] ?? json['Club'] ?? ''}'.trim();
    final cty = '${json['City'] ?? json['city'] ?? json['Location'] ?? ''}'.trim();
    final cntry = '${json['Country'] ?? json['country'] ?? ''}'.trim();

    final parsedId = id is int ? id : (int.tryParse('$id') ?? 0);
    final displayName = nameStr.isNotEmpty ? nameStr : 'Cricket Player';

    return PlayerData(
      playerId: parsedId,
      fullName: displayName,
      dob: dobVal,
      battingStyle: bat,
      bowlingStyle: bowl,
      playingRole: role,
      image: img,
      majorTeams: teams,
      clubName: club,
      city: cty,
      country: cntry,
    );
  }

  String get location {
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    if (city.isNotEmpty) return city;
    if (country.isNotEmpty) return country;
    return '';
  }

  String get avatarUrl {
    if (image.isNotEmpty && (image.startsWith('http://') || image.startsWith('https://'))) {
      return image;
    }
    if (image.isNotEmpty && image != '1' && image != '0' && image != 'null' && image != ' ') {
      return 'https://www.kricket.pk/uploads/player_images/$image';
    }
    return '';
  }

  String get derivedRole {
    if (playingRole.isNotEmpty && playingRole != 'Player' && playingRole != 'null') return playingRole;
    final bat = battingStyle.toLowerCase();
    final bowl = bowlingStyle.toLowerCase();
    if (bat.isNotEmpty && bowl.isNotEmpty && bowl != ' ' && bowl != 'null') return 'All-rounder';
    if (bowl.isNotEmpty && bowl != ' ' && bowl != 'null') return 'Bowler';
    if (bat.isNotEmpty && bat != 'null') return 'Batter';
    return 'Player';
  }
}
