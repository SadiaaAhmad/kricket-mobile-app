# Kricket.pk Mock News API Contract

The Flutter app currently consumes `MockNewsApi`, an in-process implementation of the same contract expected from the backend. It simulates network latency, JSON serialization, list/detail endpoints, and HTTP-style errors.

## Base path

`/api/v1`

## Endpoints

### `GET /articles`

Optional query parameter: `category`.

```json
{
  "success": true,
  "data": [Article],
  "meta": {
    "page": 1,
    "per_page": 4,
    "total": 4
  }
}
```

### `GET /articles/{id}`

```json
{
  "success": true,
  "data": Article
}
```

Missing IDs return:

```json
{
  "success": false,
  "error": {
    "code": "ARTICLE_NOT_FOUND",
    "message": "Article not found"
  }
}
```

## Article schema

```json
{
  "id": "babar-discipline-fitness-2026",
  "category": "PLAYER NEWS",
  "title": "Babar Azam returns focused on discipline, fitness and performance",
  "summary": "Short card and article introduction.",
  "image_url": "https://cdn.example.com/news/babar.jpg",
  "published_at": "2026-07-06T10:00:00Z",
  "read_time": "5 min read",
  "body": ["Paragraph one", "Paragraph two"],
  "source": "Pakistan Cricket Board"
}
```

The real backend should preserve these keys. Only the `NewsApi` implementation then needs to change from `MockNewsApi` to an HTTP-backed implementation; the UI and article-detail screens can remain unchanged.

## Optional HTTP mock server

The included `mock_api/db.json` can be served with JSON Server:

```powershell
npx json-server mock_api/db.json --port 3000
```

This exposes `GET /articles` and `GET /articles/{id}` for Postman or backend integration testing.
