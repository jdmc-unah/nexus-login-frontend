import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api';

  static String? loggedInEmail;
  static String? loggedInName;

  static String get effectiveEmail => loggedInEmail ?? 'test@antigravity.com';
  static String get effectiveName => loggedInName ?? 'Usuario de Prueba';


  // Helper to handle POST requests and catch connection errors
  static Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, ...data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Ocurrió un error en el portal.'};
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: Verifica que el servidor backend esté corriendo en http://localhost:3000.'
      };
    }
  }

  // Helper to handle GET requests
  static Future<Map<String, dynamic>> _get(String endpoint, [Map<String, String>? queryParams]) async {
    try {
      var uri = Uri.parse('$_baseUrl/$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http.get(uri);
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, ...data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Ocurrió un error al obtener datos.'};
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: No se pudo conectar con el servidor backend.'
      };
    }
  }

  // 1. REGISTRO
  static Future<Map<String, dynamic>> register(String name, String email, String password, {String? faceImage}) async {
    return _post('register', {
      'name': name,
      'email': email,
      'password': password,
      if (faceImage != null) 'faceImage': faceImage,
    });
  }

  // 2. VERIFICACIÓN
  static Future<Map<String, dynamic>> verify(String email, String code) async {
    return _post('verify', {
      'email': email,
      'code': code,
    });
  }

  // 3. INICIO DE SESIÓN
  static Future<Map<String, dynamic>> login(String email, String password) async {
    return _post('login', {
      'email': email,
      'password': password,
    });
  }

  // 4. RECUPERACIÓN (Usuario o Contraseña)
  static Future<Map<String, dynamic>> recover(String email, String type) async {
    return _post('recover', {
      'email': email,
      'type': type,
    });
  }

  // 5. RESTABLECER CONTRASEÑA
  static Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    return _post('reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  // 6. OBTENER BANDEJA DE CORREO SIMULADA
  static Future<List<dynamic>> fetchInbox() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/inbox'));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {}
    return [];
  }

  // 7. TMDB: OBTENER PELÍCULAS EN TENDENCIA
  static Future<Map<String, dynamic>> fetchTrendingMovies({int page = 1}) async {
    return _get('movies/trending', {'page': page.toString()});
  }

  // 8. TMDB: OBTENER PELÍCULAS MEJOR VALORADAS
  static Future<Map<String, dynamic>> fetchTopRatedMovies({int page = 1}) async {
    return _get('movies/top-rated', {'page': page.toString()});
  }

  // 9. TMDB: BUSCADOR DE PELÍCULAS
  static Future<Map<String, dynamic>> searchMovies(String query, {int page = 1}) async {
    return _get('movies/search', {'query': query, 'page': page.toString()});
  }

  // 10. TMDB: OBTENER TRAILER ID DE YOUTUBE
  static Future<String?> fetchMovieTrailerKey(int movieId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/$movieId/videos'));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'] ?? [];
        // Primero buscamos un trailer oficial en YouTube
        for (var video in results) {
          if (video['site'] == 'YouTube' && video['type'] == 'Trailer') {
            return video['key'];
          }
        }
        // Fallback a cualquier video de YouTube
        for (var video in results) {
          if (video['site'] == 'YouTube') {
            return video['key'];
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // 11. TMDB: OBTENER URL DE IMAGEN PROXIED (CORS Bypass)
  static String getProxyImageUrl(String? path, String size) {
    if (path == null || path.isEmpty) return '';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$_baseUrl/images/$size/$cleanPath';
  }

  // 12. TMDB: OBTENER PROVEEDORES DE STREAMING
  static Future<Map<String, dynamic>> fetchMovieProviders(int movieId) async {
    return _get('movies/$movieId/providers');
  }

  // 13. TMDB: OBTENER ELENCO / CRÉDITOS
  static Future<Map<String, dynamic>> fetchMovieCredits(int movieId) async {
    return _get('movies/$movieId/credits');
  }

  // 14. TMDB: OBTENER LISTA DE GÉNEROS
  static Future<Map<String, dynamic>> fetchGenres() async {
    return _get('genres');
  }

  // 15. TMDB: OBTENER PELÍCULAS POR GÉNERO
  static Future<Map<String, dynamic>> fetchMoviesByGenre(int genreId, {int page = 1}) async {
    return _get('movies/genre/$genreId', {'page': page.toString()});
  }

  // 16. FAVORITOS: OBTENER LISTA
  static Future<List<dynamic>> fetchFavorites(String email) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users/$email/favorites'));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {}
    return [];
  }

  // 17. FAVORITOS: ALTERNAR (TOGGLE)
  static Future<Map<String, dynamic>> toggleFavorite(String email, Map<String, dynamic> movie) async {
    return _post('users/$email/favorites', {'movie': movie});
  }

  // 18. VER MÁS TARDE: OBTENER LISTA
  static Future<List<dynamic>> fetchWatchLater(String email) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users/$email/watchlater'));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {}
    return [];
  }

  // 19. VER MÁS TARDE: ALTERNAR (TOGGLE)
  static Future<Map<String, dynamic>> toggleWatchLater(String email, Map<String, dynamic> movie) async {
    return _post('users/$email/watchlater', {'movie': movie});
  }

  // 20. RECOMENDACIONES IA: OBTENER LISTA DE RECOMENDACIONES PERSONALIZADAS
  static Future<List<Movie>> fetchCustomRecommendations(String email) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/recommendations?email=$email'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Movie.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  // 21. REGISTRO DE ROSTRO
  static Future<Map<String, dynamic>> registerFace(String email, String faceImage) async {
    return _post('users/$email/register-face', {
      'faceImage': faceImage,
    });
  }

  // 22. AUTENTICACIÓN POR ROSTRO
  static Future<Map<String, dynamic>> loginFace(String email, String faceImage) async {
    return _post('users/login-face', {
      'email': email,
      'faceImage': faceImage,
    });
  }
}

class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String overview;
  final String releaseDate;
  final double recommendationScore;
  final List<int> genreIds;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.overview,
    required this.releaseDate,
    required this.recommendationScore,
    required this.genreIds,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: json['title'] ?? 'Sin título',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? '',
      recommendationScore: (json['recommendation_score'] as num?)?.toDouble() ?? 0.0,
      genreIds: List<int>.from(json['genre_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'overview': overview,
      'release_date': releaseDate,
      'recommendation_score': recommendationScore,
      'genre_ids': genreIds,
    };
  }
}
