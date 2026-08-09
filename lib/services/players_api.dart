import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kricket_pk/models/player_model.dart';
import 'package:kricket_pk/models/directory_model.dart';

class PlayersApi {
  static const _baseUri = 'https://kricket.pk/backend/api';

  // In-memory caches for fast instant section loading
  static final List<DirectoryItem> _cachedDistricts = [];
  static final List<DirectoryItem> _cachedRegions = [];
  static final List<DirectoryItem> _cachedDepartments = [];
  static final List<DirectoryItem> _cachedFranchises = [];
  static final List<DirectoryItem> _cachedClubs = [];
  static final List<DirectoryItem> _cachedTeams = [];
  static final List<DirectoryItem> _cachedCities = [];
  static final List<DirectoryItem> _cachedCountries = [];
  static final List<DirectoryItem> _cachedGrounds = [];

  /// Fetch paginated players list
  Future<List<PlayerData>> getPlayers({int page = 1, int perPage = 20}) async {
    try {
      final uri = Uri.parse('$_baseUri/getallplayers').replace(
        queryParameters: {'page': '$page', 'per_page': '$perPage'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          final list = (payload['received_data']['players'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .map(PlayerData.fromJson)
                  .toList() ??
              [];
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Search players by name directly via backend getplayerbyname endpoint
  Future<List<PlayerData>> searchPlayersByName(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final response = await http.get(Uri.parse('$_baseUri/getplayerbyname/$q')).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          final rawList = payload['received_data'];
          if (rawList is List) {
            return rawList.cast<Map<String, dynamic>>().map(PlayerData.fromJson).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Districts
  Future<List<DirectoryItem>> getDistricts() async {
    if (_cachedDistricts.isNotEmpty) return List.from(_cachedDistricts);
    try {
      final response = await http.get(Uri.parse('$_baseUri/getallassociation')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['received_data'] != null && payload['received_data']['associations'] != null) {
          final rawList = payload['received_data']['associations'] as List<dynamic>;
          final items = rawList.cast<Map<String, dynamic>>().map(DirectoryItem.fromAssociation).toList();
          _cachedDistricts.clear();
          _cachedDistricts.addAll(items);
          return items;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Regions
  Future<List<DirectoryItem>> getRegions() async {
    if (_cachedRegions.isNotEmpty) return List.from(_cachedRegions);
    try {
      final response = await http.get(Uri.parse('$_baseUri/getallregion')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic>? rawList;
        if (payload['received_data'] is List) {
          rawList = payload['received_data'];
        } else if (payload['received_data'] is Map && payload['received_data']['regions'] != null) {
          rawList = payload['received_data']['regions'];
        }
        final items = rawList?.cast<Map<String, dynamic>>().map(DirectoryItem.fromRegion).toList() ?? [];
        _cachedRegions.clear();
        _cachedRegions.addAll(items);
        return items;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Departments
  Future<List<DirectoryItem>> getDepartments() async {
    if (_cachedDepartments.isNotEmpty) return List.from(_cachedDepartments);
    try {
      final response = await http.get(Uri.parse('$_baseUri/getalldepartment')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic>? rawList;
        if (payload['received_data'] is List) {
          rawList = payload['received_data'];
        } else if (payload['received_data'] is Map && payload['received_data']['departments'] != null) {
          rawList = payload['received_data']['departments'];
        }
        final items = rawList?.cast<Map<String, dynamic>>().map(DirectoryItem.fromDepartment).toList() ?? [];
        _cachedDepartments.clear();
        _cachedDepartments.addAll(items);
        return items;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Franchises
  Future<List<DirectoryItem>> getFranchises() async {
    if (_cachedFranchises.isNotEmpty) return List.from(_cachedFranchises);
    try {
      final response = await http.get(Uri.parse('$_baseUri/getallfranchise')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic>? rawList;
        if (payload['received_data'] is List) {
          rawList = payload['received_data'];
        } else if (payload['received_data'] is Map && payload['received_data']['franchises'] != null) {
          rawList = payload['received_data']['franchises'];
        }
        final items = rawList?.cast<Map<String, dynamic>>().map(DirectoryItem.fromFranchise).toList() ?? [];
        _cachedFranchises.clear();
        _cachedFranchises.addAll(items);
        return items;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Clubs with fast caching
  Future<List<DirectoryItem>> getClubs({int page = 1, int perPage = 25}) async {
    if (page == 1 && _cachedClubs.isNotEmpty) {
      return List.from(_cachedClubs.take(perPage));
    }
    try {
      final uri = Uri.parse('$_baseUri/getallclubs').replace(
        queryParameters: {'page': '$page', 'per_page': '$perPage'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic>? rawList;
        if (payload['received_data'] is List) {
          rawList = payload['received_data'];
        } else if (payload['received_data'] is Map && payload['received_data']['clubs'] != null) {
          rawList = payload['received_data']['clubs'];
        }
        final items = rawList?.cast<Map<String, dynamic>>().map(DirectoryItem.fromClub).toList() ?? [];
        final filtered = items.where((i) {
          final cName = i.rawJson['ClubName'] ?? i.rawJson['name'] ?? '';
          return cName.toString().trim().isNotEmpty && !i.title.startsWith('Club #');
        }).toList();

        if (page == 1 && filtered.isNotEmpty) {
          _cachedClubs.clear();
          _cachedClubs.addAll(filtered);
        }
        return filtered;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Teams with fast caching
  Future<List<DirectoryItem>> getTeams({int page = 1, int perPage = 25}) async {
    if (page == 1 && _cachedTeams.isNotEmpty) {
      return List.from(_cachedTeams.take(perPage));
    }
    try {
      final uri = Uri.parse('$_baseUri/getallteams').replace(
        queryParameters: {'page': '$page', 'per_page': '$perPage'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic>? rawList;
        if (payload['received_data'] is List) {
          rawList = payload['received_data'];
        } else if (payload['received_data'] is Map && payload['received_data']['teams'] != null) {
          rawList = payload['received_data']['teams'];
        }
        final items = rawList?.cast<Map<String, dynamic>>().map(DirectoryItem.fromTeam).toList() ?? [];
        final filtered = items.where((i) {
          final tName = i.rawJson['TeamName'] ?? i.rawJson['name'] ?? '';
          return tName.toString().trim().isNotEmpty && !i.title.startsWith('Team #');
        }).toList();

        if (page == 1 && filtered.isNotEmpty) {
          _cachedTeams.clear();
          _cachedTeams.addAll(filtered);
        }
        return filtered;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Cities
  Future<List<DirectoryItem>> getCities() async {
    if (_cachedCities.isNotEmpty) return List.from(_cachedCities);
    try {
      final response = await http.get(Uri.parse('$_baseUri/getallcities')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        final list = (payload['received_data'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(DirectoryItem.fromCity)
                .toList() ??
            [];
        _cachedCities.clear();
        _cachedCities.addAll(list);
        return list;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Countries
  Future<List<DirectoryItem>> getCountries() async {
    if (_cachedCountries.isNotEmpty) return List.from(_cachedCountries);
    try {
      final response = await http.get(Uri.parse('$_baseUri/getallcountries')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        final list = (payload['received_data'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(DirectoryItem.fromCountry)
                .toList() ??
            [];
        _cachedCountries.clear();
        _cachedCountries.addAll(list);
        return list;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Grounds
  Future<List<DirectoryItem>> getGrounds({int page = 1, int perPage = 25}) async {
    if (page == 1 && _cachedGrounds.isNotEmpty) return List.from(_cachedGrounds.take(perPage));
    try {
      final uri = Uri.parse('$_baseUri/getallgrounds').replace(
        queryParameters: {'page': '$page', 'per_page': '$perPage'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic>? rawList;
        if (payload['received_data'] is List) {
          rawList = payload['received_data'];
        } else if (payload['received_data'] is Map && payload['received_data']['grounds'] != null) {
          rawList = payload['received_data']['grounds'];
        }
        final list = rawList?.cast<Map<String, dynamic>>().map(DirectoryItem.fromGround).toList() ?? [];
        if (page == 1 && list.isNotEmpty) {
          _cachedGrounds.clear();
          _cachedGrounds.addAll(list);
        }
        return list;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Player Profile by ID
  Future<PlayerData?> getPlayerProfile(int playerId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/selectplayerbyid/$playerId')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          final data = payload['received_data'];
          if (data is List && data.isNotEmpty) {
            return PlayerData.fromJson(data.first);
          } else if (data is Map<String, dynamic>) {
            return PlayerData.fromJson(data);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch Player Batting Career Stats
  Future<List<Map<String, dynamic>>> getPlayerBatting(int playerId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/getplayerbatting/$playerId')).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          final list = payload['received_data'];
          if (list is List) {
            return list.cast<Map<String, dynamic>>();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Player Bowling Career Stats
  Future<List<Map<String, dynamic>>> getPlayerBowling(int playerId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/getplayerbowling/$playerId')).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          final list = payload['received_data'];
          if (list is List) {
            return list.cast<Map<String, dynamic>>();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Association Detail by ID
  Future<Map<String, dynamic>?> getAssociationDetail(int associationId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/getassociationbyid/$associationId')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          return payload['received_data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch Region Detail by ID
  Future<Map<String, dynamic>?> getRegionDetail(int regionId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/getregionbyid/$regionId')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          return payload['received_data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch Department Detail by ID
  Future<Map<String, dynamic>?> getDepartmentDetail(int departmentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/getdepartmentbyid/$departmentId')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          final data = payload['received_data'];
          if (data is List && data.isNotEmpty) return data.first as Map<String, dynamic>;
          if (data is Map<String, dynamic>) return data;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch Teams by Department ID
  Future<List<DirectoryItem>> getTeamsByDepartment(int departmentId) async {
    try {
      final allTeams = await getTeams(page: 1, perPage: 200);
      return allTeams.where((item) {
        final deptId = item.rawJson['DepartmentId'] ?? item.rawJson['department_id'];
        return deptId == departmentId || '${item.rawJson['DepartmentId']}' == '$departmentId';
      }).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch Franchise Detail by ID
  Future<Map<String, dynamic>?> getFranchiseDetail(int franchiseId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/getfranchisebyid/$franchiseId')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          final data = payload['received_data'];
          if (data is List && data.isNotEmpty) return data.first as Map<String, dynamic>;
          if (data is Map<String, dynamic>) return data;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch Teams by Franchise ID
  Future<List<DirectoryItem>> getTeamsByFranchise(int franchiseId) async {
    try {
      final allTeams = await getTeams(page: 1, perPage: 200);
      return allTeams.where((item) {
        final fId = item.rawJson['FranchiseId'] ?? item.rawJson['franchise_id'];
        return fId == franchiseId || '${item.rawJson['FranchiseId']}' == '$franchiseId';
      }).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch Club Detail by ID
  Future<Map<String, dynamic>?> getClubDetail(int clubId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/getclubbyid/$clubId')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          return payload['received_data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch Ground Detail by ID
  Future<Map<String, dynamic>?> getGroundDetail(int groundId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/getgroundbyid/$groundId')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          final data = payload['received_data'];
          if (data is List && data.isNotEmpty) return data.first as Map<String, dynamic>;
          if (data is Map<String, dynamic>) return data;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch Clubs by City ID or City Name
  Future<List<DirectoryItem>> getClubsByCity(int cityId, String cityName) async {
    try {
      final allClubs = await getClubs(page: 1, perPage: 200);
      final cName = cityName.trim().toLowerCase();
      return allClubs.where((item) {
        final cId = item.rawJson['CityId'] ?? item.rawJson['cityid'];
        final itemCity = '${item.rawJson['CityName'] ?? item.rawJson['city'] ?? ''}'.trim().toLowerCase();
        return (cId != null && '$cId' == '$cityId') || (cName.isNotEmpty && itemCity == cName);
      }).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch Teams by City ID or City Name
  Future<List<DirectoryItem>> getTeamsByCity(int cityId, String cityName) async {
    try {
      final allTeams = await getTeams(page: 1, perPage: 200);
      final cName = cityName.trim().toLowerCase();
      return allTeams.where((item) {
        final cId = item.rawJson['CityId'] ?? item.rawJson['cityid'];
        final itemCity = '${item.rawJson['CityName'] ?? item.rawJson['city'] ?? ''}'.trim().toLowerCase();
        return (cId != null && '$cId' == '$cityId') || (cName.isNotEmpty && itemCity == cName);
      }).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch Grounds by City ID or City Name
  Future<List<DirectoryItem>> getGroundsByCity(int cityId, String cityName) async {
    try {
      final allGrounds = await getGrounds(page: 1, perPage: 200);
      final cName = cityName.trim().toLowerCase();
      return allGrounds.where((item) {
        final cId = item.rawJson['CityId'] ?? item.rawJson['cityid'];
        final itemCity = '${item.rawJson['CityName'] ?? item.rawJson['city'] ?? ''}'.trim().toLowerCase();
        return (cId != null && '$cId' == '$cityId') || (cName.isNotEmpty && itemCity == cName);
      }).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch Franchises by Country Code
  Future<List<DirectoryItem>> getFranchisesByCountry(int countryCode) async {
    try {
      final allFranchises = await getFranchises();
      return allFranchises.where((item) {
        final cCode = item.rawJson['CountryCode'] ?? item.rawJson['countryid'];
        return cCode == countryCode || '$cCode' == '$countryCode';
      }).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch Team Detail by ID
  Future<Map<String, dynamic>?> getTeamDetail(int teamId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/getteambyid/$teamId')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          return payload['received_data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch Squad players by Team ID
  Future<List<Map<String, dynamic>>> getSquadByTeam(int teamId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUri/getsquadbyteam/$teamId')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload['status'] == true && payload['received_data'] != null) {
          final list = payload['received_data'];
          if (list is List) {
            return list.cast<Map<String, dynamic>>();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch Clubs by Association ID
  Future<List<DirectoryItem>> getClubsByAssociation(int associationId) async {
    try {
      final allClubs = await getClubs(page: 1, perPage: 200);
      return allClubs.where((item) {
        final assocId = item.rawJson['AssociationId'] ?? item.rawJson['association_id'];
        return assocId == associationId || '${item.rawJson['AssociationId']}' == '$associationId';
      }).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch Teams by District/Association ID
  Future<List<DirectoryItem>> getTeamsByAssociation(int associationId) async {
    try {
      final allTeams = await getTeams(page: 1, perPage: 200);
      return allTeams.where((item) {
        final distId = item.rawJson['DistrictId'] ?? item.rawJson['AssociationId'] ?? item.rawJson['district_id'];
        return distId == associationId || '${item.rawJson['DistrictId']}' == '$associationId';
      }).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch Associations by Region ID
  Future<List<DirectoryItem>> getAssociationsByRegion(int regionId) async {
    try {
      final allAssocs = await getDistricts();
      return allAssocs.where((item) {
        final regId = item.rawJson['RegionId'] ?? item.rawJson['region_id'];
        return regId == regionId || '${item.rawJson['RegionId']}' == '$regionId';
      }).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch Teams by Region ID
  Future<List<DirectoryItem>> getTeamsByRegion(int regionId) async {
    try {
      final allTeams = await getTeams(page: 1, perPage: 200);
      return allTeams.where((item) {
        final regId = item.rawJson['RegionId'] ?? item.rawJson['region_id'];
        return regId == regionId || '${item.rawJson['RegionId']}' == '$regionId';
      }).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch Clubs by Region ID
  Future<List<DirectoryItem>> getClubsByRegion(int regionId) async {
    try {
      final allClubs = await getClubs(page: 1, perPage: 200);
      return allClubs.where((item) {
        final regId = item.rawJson['RegionId'] ?? item.rawJson['region_id'];
        return regId == regionId || '${item.rawJson['RegionId']}' == '$regionId';
      }).toList();
    } catch (_) {}
    return [];
  }
}
