import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kricket_pk/models/article_model.dart';
import 'package:kricket_pk/data/real_articles.dart';

class PaginatedArticlesResult {
  final List<ArticleData> articles;
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;

  PaginatedArticlesResult({
    required this.articles,
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });
}

abstract interface class NewsApi {
  Future<List<ArticleData>> getArticles({String? category, int limit = 10, int start = 0});
  Future<ArticleData> getArticle(String id);
}

class KricketNewsApi implements NewsApi {
  const KricketNewsApi({http.Client? client}) : _client = client;

  static const _baseUri = 'https://kricket.pk/backend/api';
  final http.Client? _client;

  /// Fetch paginated news articles directly from allarticleweb API
  Future<PaginatedArticlesResult> getPaginatedArticles({
    int page = 1,
    int perPage = 16,
    String newsType = 'latest',
  }) async {
    final uri = Uri.parse('$_baseUri/allarticleweb').replace(queryParameters: {
      'page': '$page',
      'per_page': '$perPage',
      'newstype': newsType,
    });
    final client = _client ?? http.Client();
    try {
      final response = await client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (payload['status'] == true && payload['received_data'] != null) {
          final received = payload['received_data'] as Map<String, dynamic>;
          final rawArticles = (received['articles'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()
              .map(ArticleData.fromBackendJson)
              .toList();

          final pag = received['pagination'] as Map<String, dynamic>?;
          final totalItems = pag?['total_items'] as int? ?? 3518;
          final totalPages = pag?['total_pages'] as int? ?? 196;
          final currentPage = pag?['current_page'] as int? ?? page;

          return PaginatedArticlesResult(
            articles: rawArticles,
            currentPage: currentPage,
            perPage: perPage,
            totalItems: totalItems,
            totalPages: totalPages,
          );
        }
      }
    } catch (_) {}
    return PaginatedArticlesResult(
      articles: [],
      currentPage: page,
      perPage: perPage,
      totalItems: 0,
      totalPages: 1,
    );
  }

  @override
  Future<List<ArticleData>> getArticles({String? category, int limit = 10, int start = 0}) async {
    final uri = Uri.parse('$_baseUri/gettoparticles').replace(queryParameters: {'Limit': '$limit', 'Start': '$start'});
    final client = _client ?? http.Client();
    try {
      final response = await client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw NewsApiException(response.statusCode, 'Unable to load articles');
      final payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (payload['status'] != true) throw const NewsApiException(502, 'Kricket API returned an unsuccessful response');
      final received = payload['received_data'] as Map<String, dynamic>?;
      final articles = (received?['articles'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ArticleData.fromBackendJson)
          .where((article) => category == null || article.category == category)
          .toList();
      return articles;
    } on NewsApiException {
      rethrow;
    } catch (_) {
      throw const NewsApiException(503, 'Kricket articles service is unavailable');
    } finally {
      if (_client == null) client.close();
    }
  }

  @override
  Future<ArticleData> getArticle(String id) async {
    final possibleUris = [
      Uri.parse('$_baseUri/getarticlebyid').replace(queryParameters: {'id': id}),
      Uri.parse('$_baseUri/getarticlebyid').replace(queryParameters: {'Id': id}),
      Uri.parse('$_baseUri/getarticlebyid').replace(queryParameters: {'ArticleId': id}),
    ];
    
    final client = _client ?? http.Client();
    try {
      for (var uri in possibleUris) {
        final response = await client.get(uri).timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) continue;
        
        final payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (payload['status'] != true) continue;
        
        final receivedList = payload['received_data'] as List<dynamic>?;
        if (receivedList != null && receivedList.isNotEmpty) {
          final received = receivedList.first as Map<String, dynamic>;
          return ArticleData.fromBackendJson(received);
        }
      }
      
      throw const NewsApiException(404, 'Article not found');
    } on NewsApiException {
      rethrow;
    } catch (_) {
      throw const NewsApiException(503, 'Kricket article service is unavailable');
    } finally {
      if (_client == null) client.close();
    }
  }
}

class MockNewsApi implements NewsApi {
  const MockNewsApi({this.latency = const Duration(milliseconds: 450)});
  final Duration latency;

  @override
  Future<List<ArticleData>> getArticles({String? category, int limit = 10, int start = 0}) async {
    await Future<void>.delayed(latency);
    final response = <String, dynamic>{
      'success': true,
      'data': [for (final article in realArticles) article.toJson()],
      'meta': {'page': 1, 'per_page': realArticles.length, 'total': realArticles.length},
    };
    final items = (response['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ArticleData.fromJson)
        .where((article) => category == null || article.category == category)
        .toList();
    return items;
  }

  @override
  Future<ArticleData> getArticle(String id) async {
    await Future<void>.delayed(latency);
    final match = realArticles.where((article) => article.id == id);
    if (match.isEmpty) throw const NewsApiException(404, 'Article not found');
    return ArticleData.fromJson(match.first.toJson());
  }
}

class FallbackNewsApi implements NewsApi {
  const FallbackNewsApi(this.primary, this.fallback);
  final NewsApi primary;
  final NewsApi fallback;

  @override
  Future<List<ArticleData>> getArticles({String? category, int limit = 10, int start = 0}) async {
    try {
      final items = await primary.getArticles(category: category, limit: limit, start: start);
      if (items.isNotEmpty) return items;
      return fallback.getArticles(category: category, limit: limit, start: start);
    } catch (_) {
      return fallback.getArticles(category: category, limit: limit, start: start);
    }
  }

  @override
  Future<ArticleData> getArticle(String id) async {
    try {
      return await primary.getArticle(id);
    } catch (_) {
      return fallback.getArticle(id);
    }
  }
}

class NewsApiException implements Exception {
  const NewsApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'NewsApiException($statusCode): $message';
}
