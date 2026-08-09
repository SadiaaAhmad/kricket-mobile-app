class DirectoryItem {
  final int id;
  final String title;
  final String subtitle;
  final String category;
  final Map<String, dynamic> rawJson;

  const DirectoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.rawJson,
  });

  factory DirectoryItem.fromAssociation(Map<String, dynamic> json) {
    final id = json['AssociationId'] ?? json['id'] ?? 0;
    final name = '${json['AssociationName'] ?? json['name'] ?? ''}'.trim();
    final reg = '${json['RegionName'] ?? ''}'.trim();
    return DirectoryItem(
      id: id is int ? id : (int.tryParse('$id') ?? 0),
      title: name.isNotEmpty ? name : 'District #$id',
      subtitle: reg.isNotEmpty ? 'Region: $reg' : 'District Association',
      category: 'District',
      rawJson: json,
    );
  }

  factory DirectoryItem.fromRegion(Map<String, dynamic> json) {
    final id = json['RegionId'] ?? json['id'] ?? 0;
    final name = '${json['RegionName'] ?? json['name'] ?? ''}'.trim();
    return DirectoryItem(
      id: id is int ? id : (int.tryParse('$id') ?? 0),
      title: name.isNotEmpty ? name : 'Region #$id',
      subtitle: 'Cricket Region',
      category: 'Region',
      rawJson: json,
    );
  }

  factory DirectoryItem.fromDepartment(Map<String, dynamic> json) {
    final id = json['DepartmentId'] ?? json['id'] ?? 0;
    final name = '${json['DepartmentName'] ?? json['name'] ?? ''}'.trim();
    return DirectoryItem(
      id: id is int ? id : (int.tryParse('$id') ?? 0),
      title: name.isNotEmpty ? name : 'Department #$id',
      subtitle: 'Cricket Department',
      category: 'Department',
      rawJson: json,
    );
  }

  factory DirectoryItem.fromFranchise(Map<String, dynamic> json) {
    final id = json['FranchiseId'] ?? json['id'] ?? 0;
    final name = '${json['FranchiseName'] ?? json['name'] ?? ''}'.trim();
    final cCode = json['CountryCode'] ?? 0;
    return DirectoryItem(
      id: id is int ? id : (int.tryParse('$id') ?? 0),
      title: name.isNotEmpty ? name : 'Franchise #$id',
      subtitle: cCode == 91 ? 'IPL Franchise' : (cCode == 92 ? 'PSL Franchise' : 'Franchise Team'),
      category: 'Franchise',
      rawJson: json,
    );
  }

  factory DirectoryItem.fromClub(Map<String, dynamic> json) {
    final id = json['ClubId'] ?? json['id'] ?? 0;
    final name = '${json['ClubName'] ?? json['name'] ?? ''}'.trim();
    final assoc = '${json['AssociationName'] ?? ''}'.trim();
    return DirectoryItem(
      id: id is int ? id : (int.tryParse('$id') ?? 0),
      title: name.isNotEmpty ? name : 'Club #$id',
      subtitle: assoc.isNotEmpty ? assoc : 'Cricket Club',
      category: 'Club',
      rawJson: json,
    );
  }

  factory DirectoryItem.fromTeam(Map<String, dynamic> json) {
    final id = json['TeamId'] ?? json['id'] ?? 0;
    final name = '${json['TeamName'] ?? json['name'] ?? ''}'.trim();
    final lvl = '${json['Level'] ?? json['Format'] ?? ''}'.trim();
    return DirectoryItem(
      id: id is int ? id : (int.tryParse('$id') ?? 0),
      title: name.isNotEmpty ? name : 'Team #$id',
      subtitle: lvl.isNotEmpty ? '$lvl Team' : 'Cricket Team',
      category: 'Team',
      rawJson: json,
    );
  }

  factory DirectoryItem.fromCity(Map<String, dynamic> json) {
    final id = json['CityId'] ?? json['id'] ?? 0;
    final name = '${json['CityName'] ?? json['name'] ?? ''}'.trim();
    return DirectoryItem(
      id: id is int ? id : (int.tryParse('$id') ?? 0),
      title: name.isNotEmpty ? name : 'City #$id',
      subtitle: 'City',
      category: 'City',
      rawJson: json,
    );
  }

  factory DirectoryItem.fromCountry(Map<String, dynamic> json) {
    final id = json['CountryCode'] ?? json['id'] ?? 0;
    final name = '${json['CountryName'] ?? json['name'] ?? ''}'.trim();
    final board = '${json['BoardName'] ?? ''}'.trim();
    return DirectoryItem(
      id: id is int ? id : (int.tryParse('$id') ?? 0),
      title: name.isNotEmpty ? name : 'Country #$id',
      subtitle: board.isNotEmpty ? board : 'ICC Country Board',
      category: 'Country',
      rawJson: json,
    );
  }

  factory DirectoryItem.fromGround(Map<String, dynamic> json) {
    final id = json['GroundId'] ?? json['id'] ?? 0;
    final name = '${json['GroundName'] ?? json['name'] ?? ''}'.trim();
    final loc = '${json['Address'] ?? json['Location'] ?? ''}'.trim();
    return DirectoryItem(
      id: id is int ? id : (int.tryParse('$id') ?? 0),
      title: name.isNotEmpty ? name : 'Ground #$id',
      subtitle: loc.isNotEmpty ? loc : 'Cricket Ground',
      category: 'Ground',
      rawJson: json,
    );
  }
}
