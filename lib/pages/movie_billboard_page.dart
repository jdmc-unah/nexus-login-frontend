import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/futuristic_button.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/glow_card.dart';

class MovieBillboardPage extends StatefulWidget {
  const MovieBillboardPage({super.key});

  @override
  State<MovieBillboardPage> createState() => _MovieBillboardPageState();
}

class _MovieBillboardPageState extends State<MovieBillboardPage> {
  final _searchController = TextEditingController();
  
  List<dynamic> _trendingMovies = [];
  List<dynamic> _topRatedMovies = [];
  List<dynamic> _searchResults = [];
  
  bool _isLoadingTrending = true;
  bool _isLoadingTopRated = false;
  bool _isSearching = false;
  
  Map<String, dynamic>? _selectedMovie;
  String? _currentTrailerKey;
  String? _fetchedTrailerKey;


  // Filter/Genre states
  List<dynamic> _genres = [];
  String _selectedFilterKey = 'all';
  List<dynamic> _genreMovies = [];
  bool _isLoadingGenreMovies = false;

  // User personal lists
  List<dynamic> _favorites = [];
  List<dynamic> _watchLater = [];

  // Movie credits and providers
  List<dynamic> _cast = [];
  Map<String, dynamic>? _watchProviders;
  bool _isLoadingDetails = false;

  // Pagination scroll controllers
  final ScrollController _mainVerticalScrollController = ScrollController();
  final ScrollController _trendingScrollController = ScrollController();
  final ScrollController _topRatedScrollController = ScrollController();

  // Pagination states
  int _trendingPage = 1;
  int _topRatedPage = 1;
  int _searchPage = 1;
  int _genrePage = 1;
  
  bool _isLoadingMoreTrending = false;
  bool _isLoadingMoreTopRated = false;
  bool _isLoadingMoreSearch = false;
  bool _isLoadingMoreGenre = false;
  
  bool _hasMoreTrending = true;
  bool _hasMoreTopRated = true;
  bool _hasMoreSearch = true;
  bool _hasMoreGenre = true;

  // Quantum AI recommendations state
  List<Movie> _recommendations = [];
  bool _isLoadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _loadGenresAndUserLists();
    _loadRecommendations();
    
    // Attach scroll listeners
    _mainVerticalScrollController.addListener(() {
      if (_mainVerticalScrollController.position.pixels >= _mainVerticalScrollController.position.maxScrollExtent - 300) {
        if (_isSearching) {
          _loadMoreSearch();
        } else if (_selectedFilterKey.startsWith('genre-')) {
          _loadMoreGenre();
        }
      }
    });

    _trendingScrollController.addListener(() {
      if (_trendingScrollController.position.pixels >= _trendingScrollController.position.maxScrollExtent - 200) {
        _loadMoreTrending();
      }
    });

    _topRatedScrollController.addListener(() {
      if (_topRatedScrollController.position.pixels >= _topRatedScrollController.position.maxScrollExtent - 200) {
        _loadMoreTopRated();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mainVerticalScrollController.dispose();
    _trendingScrollController.dispose();
    _topRatedScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoadingTrending = true;
      _isLoadingTopRated = true;
      _trendingPage = 1;
      _topRatedPage = 1;
      _hasMoreTrending = true;
      _hasMoreTopRated = true;
    });

    final trendingRes = await ApiService.fetchTrendingMovies(page: 1);
    final topRatedRes = await ApiService.fetchTopRatedMovies(page: 1);

    if (mounted) {
      setState(() {
        _isLoadingTrending = false;
        _isLoadingTopRated = false;
        
        if (trendingRes['success'] == true) {
          _trendingMovies = trendingRes['results'] ?? [];
          final totalPages = trendingRes['total_pages'] ?? 1;
          _hasMoreTrending = _trendingPage < totalPages;
        }
        if (topRatedRes['success'] == true) {
          _topRatedMovies = topRatedRes['results'] ?? [];
          final totalPages = topRatedRes['total_pages'] ?? 1;
          _hasMoreTopRated = _topRatedPage < totalPages;
        }
      });
    }
  }

  Future<void> _loadGenresAndUserLists() async {
    final genresRes = await ApiService.fetchGenres();
    final favs = await ApiService.fetchFavorites(ApiService.effectiveEmail);
    final wl = await ApiService.fetchWatchLater(ApiService.effectiveEmail);
    if (mounted) {
      setState(() {
        if (genresRes['success'] == true) {
          _genres = genresRes['genres'] ?? [];
        }
        _favorites = favs;
        _watchLater = wl;
      });
    }
  }

  void _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _selectedFilterKey = 'all';
      _genreMovies = [];
      _isSearching = true;
      _isLoadingTrending = true;
      _searchPage = 1;
      _hasMoreSearch = true;
    });

    final res = await ApiService.searchMovies(query, page: 1);

    if (mounted) {
      setState(() {
        _isLoadingTrending = false;
        if (res['success'] == true) {
          _searchResults = res['results'] ?? [];
          final totalPages = res['total_pages'] ?? 1;
          _hasMoreSearch = _searchPage < totalPages;
        }
      });
    }
  }

  void _handleClearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = [];
    });
  }

  void _handleFilterChanged(String key) async {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _selectedFilterKey = key;
      _genrePage = 1;
      _hasMoreGenre = true;
    });

    if (key.startsWith('genre-')) {
      final genreIdStr = key.substring(6);
      final genreId = int.tryParse(genreIdStr);
      if (genreId != null) {
        setState(() {
          _isLoadingGenreMovies = true;
        });
        final res = await ApiService.fetchMoviesByGenre(genreId, page: 1);
        if (mounted && _selectedFilterKey == key) {
          setState(() {
            _isLoadingGenreMovies = false;
            if (res['success'] == true) {
              _genreMovies = res['results'] ?? [];
              final totalPages = res['total_pages'] ?? 1;
              _hasMoreGenre = _genrePage < totalPages;
            }
          });
        }
      }
    }
  }

  Future<void> _loadMoreTrending() async {
    if (_isLoadingMoreTrending || !_hasMoreTrending) return;
    
    setState(() {
      _isLoadingMoreTrending = true;
    });
    
    final nextPage = _trendingPage + 1;
    final res = await ApiService.fetchTrendingMovies(page: nextPage);
    
    if (mounted) {
      setState(() {
        _isLoadingMoreTrending = false;
        if (res['success'] == true) {
          final newResults = res['results'] ?? [];
          if (newResults.isNotEmpty) {
            _trendingPage = nextPage;
            _trendingMovies.addAll(newResults);
          }
          final totalPages = res['total_pages'] ?? 1;
          _hasMoreTrending = _trendingPage < totalPages;
        }
      });
    }
  }

  Future<void> _loadMoreTopRated() async {
    if (_isLoadingMoreTopRated || !_hasMoreTopRated) return;
    
    setState(() {
      _isLoadingMoreTopRated = true;
    });
    
    final nextPage = _topRatedPage + 1;
    final res = await ApiService.fetchTopRatedMovies(page: nextPage);
    
    if (mounted) {
      setState(() {
        _isLoadingMoreTopRated = false;
        if (res['success'] == true) {
          final newResults = res['results'] ?? [];
          if (newResults.isNotEmpty) {
            _topRatedPage = nextPage;
            _topRatedMovies.addAll(newResults);
          }
          final totalPages = res['total_pages'] ?? 1;
          _hasMoreTopRated = _topRatedPage < totalPages;
        }
      });
    }
  }

  Future<void> _loadMoreSearch() async {
    if (_isLoadingMoreSearch || !_hasMoreSearch) return;
    
    setState(() {
      _isLoadingMoreSearch = true;
    });
    
    final query = _searchController.text;
    final nextPage = _searchPage + 1;
    final res = await ApiService.searchMovies(query, page: nextPage);
    
    if (mounted) {
      setState(() {
        _isLoadingMoreSearch = false;
        if (res['success'] == true) {
          final newResults = res['results'] ?? [];
          if (newResults.isNotEmpty) {
            _searchPage = nextPage;
            _searchResults.addAll(newResults);
          }
          final totalPages = res['total_pages'] ?? 1;
          _hasMoreSearch = _searchPage < totalPages;
        }
      });
    }
  }

  Future<void> _loadMoreGenre() async {
    if (_isLoadingMoreGenre || !_hasMoreGenre) return;
    
    final genreIdStr = _selectedFilterKey.substring(6);
    final genreId = int.tryParse(genreIdStr);
    if (genreId == null) return;
    
    setState(() {
      _isLoadingMoreGenre = true;
    });
    
    final nextPage = _genrePage + 1;
    final res = await ApiService.fetchMoviesByGenre(genreId, page: nextPage);
    
    if (mounted && _selectedFilterKey == 'genre-$genreId') {
      setState(() {
        _isLoadingMoreGenre = false;
        if (res['success'] == true) {
          final newResults = res['results'] ?? [];
          if (newResults.isNotEmpty) {
            _genrePage = nextPage;
            _genreMovies.addAll(newResults);
          }
          final totalPages = res['total_pages'] ?? 1;
          _hasMoreGenre = _genrePage < totalPages;
        }
      });
    }
  }


  void _openDetails(Map<String, dynamic> movie) async {
    setState(() {
      _selectedMovie = movie;
      _isLoadingDetails = true;
      _currentTrailerKey = null;
      _fetchedTrailerKey = null;
      _watchProviders = null;
      _cast = [];
    });

    final id = movie['id'] as int;

    final results = await Future.wait([
      ApiService.fetchMovieTrailerKey(id),
      ApiService.fetchMovieCredits(id),
      ApiService.fetchMovieProviders(id),
    ]);

    if (mounted && _selectedMovie?['id'] == id) {
      setState(() {
        _fetchedTrailerKey = results[0] as String?;
        final credits = results[1] as Map<String, dynamic>?;
        if (credits != null && credits['success'] == true) {
          _cast = credits['cast'] ?? [];
        }
        final providers = results[2] as Map<String, dynamic>?;
        if (providers != null && providers['success'] == true) {
          _watchProviders = providers;
        }
        _isLoadingDetails = false;
      });
    }
  }

  void _closeDetails() {
    setState(() {
      _selectedMovie = null;
      _currentTrailerKey = null;
      _fetchedTrailerKey = null;
    });
  }

  void _toggleFavorite(Map<String, dynamic> movie) async {
    final res = await ApiService.toggleFavorite(ApiService.effectiveEmail, movie);
    if (res['success'] == true) {
      setState(() {
        _favorites = res['favorites'] ?? [];
      });
      _loadRecommendations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Favoritos actualizados.'),
          backgroundColor: AppColors.acentoVioleta,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _toggleWatchLater(Map<String, dynamic> movie) async {
    final res = await ApiService.toggleWatchLater(ApiService.effectiveEmail, movie);
    if (res['success'] == true) {
      setState(() {
        _watchLater = res['watchLater'] ?? [];
      });
      _loadRecommendations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Ver más tarde actualizado.'),
          backgroundColor: AppColors.acentoVioleta,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 750;

    return GradientBackground(
      child: Stack(
        children: [
          // Main Billboard Content
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.2),
              elevation: 0,
              centerTitle: false,
              iconTheme: const IconThemeData(color: AppColors.acentoMagenta),
              title: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _handleFilterChanged('all'),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.acentoMagenta, AppColors.acentoVioleta],
                    ).createShader(bounds),
                    child: const Text(
                      'NEXUS CINEMA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 20),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.textoSecundario,
                      ),
                      onPressed: () {
                        ApiService.loggedInEmail = null;
                        ApiService.loggedInName = null;
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      },
                      tooltip: 'Cerrar Sesión',
                    ),
                  ),
                ),
              ],
            ),
            drawer: isWide
                ? null
                : Drawer(
                    backgroundColor: AppColors.fondoBase,
                    child: _buildSidebarContent(isDrawer: true),
                  ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Persistent Sidebar for wider screens
                if (isWide)
                  Container(
                    width: 240,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: AppColors.acentoVioleta.withValues(alpha: 0.2),
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: _buildSidebarContent(isDrawer: false),
                  ),
                // Main Content View
                Expanded(
                  child: SingleChildScrollView(
                    controller: _mainVerticalScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search Section
                        _buildSearchBar(),
                        const SizedBox(height: 40),

                        if (_isSearching)
                          _buildSearchResultsSection()
                        else if (_selectedFilterKey == 'favorites')
                          _buildFavoritesSection()
                        else if (_selectedFilterKey == 'watchlater')
                          _buildWatchLaterSection()
                        else if (_selectedFilterKey.startsWith('genre-'))
                          _buildGenreResultsSection()

                        else ...[
                          // Quantum AI recommendations Section
                          _buildRecommendationsSection(),

                          // Favorites Section
                          if (_favorites.isNotEmpty) ...[
                            _buildMovieSection(
                              title: 'Mis Películas Favoritas',
                              movies: _favorites,
                              isLoading: false,
                              isLoadingMore: false,
                            ),
                            const SizedBox(height: 48),
                          ],

                          // Watch Later Section
                          if (_watchLater.isNotEmpty) ...[
                            _buildMovieSection(
                              title: 'Ver más tarde',
                              movies: _watchLater,
                              isLoading: false,
                              isLoadingMore: false,
                            ),
                            const SizedBox(height: 48),
                          ],

                          // Trending Section
                          _buildMovieSection(
                            title: 'Tendencias en Órbita',
                            movies: _trendingMovies,
                            isLoading: _isLoadingTrending,
                            isLoadingMore: _isLoadingMoreTrending,
                            scrollController: _trendingScrollController,
                          ),
                          const SizedBox(height: 48),

                          // Top Rated Section
                          _buildMovieSection(
                            title: 'Calificaciones Supremas',
                            movies: _topRatedMovies,
                            isLoading: _isLoadingTopRated,
                            isLoadingMore: _isLoadingMoreTopRated,
                            scrollController: _topRatedScrollController,
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom Glassmorphic Details Overlay
          if (_selectedMovie != null) _buildDetailsOverlay(),
        ],
      ),
    );
  }


  Widget _buildSearchBar() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.acentoVioleta.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 1,
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _handleSearch,
          style: const TextStyle(color: AppColors.textoPrincipal),
          cursorColor: AppColors.acentoMagenta,
          decoration: InputDecoration(
            hintText: 'Buscar películas por firma...',
            hintStyle: const TextStyle(color: AppColors.textoSecundario, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textoSecundario, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textoSecundario, size: 20),
                    onPressed: _handleClearSearch,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: AppColors.acentoVioleta.withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.acentoMagenta,
                width: 1.8,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
    });
    final list = await ApiService.fetchCustomRecommendations(ApiService.effectiveEmail);
    if (mounted) {
      setState(() {
        _recommendations = list;
        _isLoadingRecommendations = false;
      });
    }
  }

  Widget _buildRecommendationsSection() {
    if (_isLoadingRecommendations) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUGERIDO POR IA CUÁNTICA',
            style: TextStyle(
              color: AppColors.acentoMagenta,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.acentoMagenta),
            ),
          ),
          SizedBox(height: 48),
        ],
      );
    }

    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUGERIDO POR IA CUÁNTICA',
          style: TextStyle(
            color: AppColors.textoPrincipal,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final movie = _recommendations[index];
              final backdrop = movie.backdropPath;
              final matchPercentage = (movie.recommendationScore * 100).toStringAsFixed(0);

              return Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 20),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _openDetails(movie.toJson()),
                    child: GlowCard(
                      width: 280,
                      height: 160,
                      animateFloating: true,
                      padding: EdgeInsets.zero,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: backdrop != null
                                ? Image.network(
                                    ApiService.getProxyImageUrl(backdrop, 'w780'),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.purple.withValues(alpha: 0.1),
                                      child: const Icon(Icons.movie_creation_outlined, color: AppColors.textoSecundario, size: 48),
                                    ),
                                  )
                                : Container(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    child: const Icon(Icons.movie_creation_outlined, color: AppColors.textoSecundario, size: 48),
                                  ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.2),
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Text(
                              movie.title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textoPrincipal,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.acentoMagenta.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.acentoMagenta,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.acentoMagenta.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                '$matchPercentage% MATCH',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildMovieSection({
    required String title,
    required List<dynamic> movies,
    required bool isLoading,
    bool isLoadingMore = false,
    ScrollController? scrollController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        if (isLoading)
          const SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.acentoMagenta),
            ),
          )
        else if (movies.isEmpty)
          const SizedBox(
            height: 300,
            child: Center(
              child: Text(
                'No se encontraron películas.',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ),
          )
        else
          SizedBox(
            height: 340,
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: movies.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == movies.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: CircularProgressIndicator(color: AppColors.acentoMagenta),
                    ),
                  );
                }
                final movie = movies[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: _MovieCard(
                    movie: movie,
                    onTap: () => _openDetails(movie),
                  ),
                );
              },
            ),
          )
      ],
    );
  }

  Widget _buildSearchResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.saved_search_rounded, color: AppColors.acentoMagenta),
            const SizedBox(width: 10),
            Text(
              'RESULTADOS DE BÚSQUEDA (${_searchResults.length})',
              style: const TextStyle(
                color: AppColors.textoPrincipal,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_isLoadingTrending)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: CircularProgressIndicator(color: AppColors.acentoMagenta),
            ),
          )
        else if (_searchResults.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Text(
                'No se encontraron resultados para la consulta cuántica.',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ),
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 340,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final movie = _searchResults[index];
              return _MovieCard(
                movie: movie,
                onTap: () => _openDetails(movie),
              );
            },
          ),
          if (_isLoadingMoreSearch)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.acentoMagenta),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSidebarContent({bool isDrawer = false}) {
    return Container(
      color: AppColors.fondoBase.withValues(alpha: 0.95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top spacing: safe area for drawer, simple padding for sidebar
          SizedBox(height: isDrawer ? MediaQuery.of(context).padding.top + 16 : 24),
          // Navigation items list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _buildSidebarItem(
                  icon: Icons.home_rounded,
                  title: 'Inicio',
                  valueKey: 'all',
                  isDrawer: isDrawer,
                ),
                _buildSidebarItem(
                  icon: Icons.favorite_rounded,
                  title: 'Favoritas',
                  valueKey: 'favorites',
                  isDrawer: isDrawer,
                ),
                _buildSidebarItem(
                  icon: Icons.bookmark_rounded,
                  title: 'Ver más tarde',
                  valueKey: 'watchlater',
                  isDrawer: isDrawer,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'GÉNEROS',
                    style: TextStyle(
                      color: AppColors.acentoMagenta,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                ..._genres.map((g) {
                  final id = g['id'];
                  final name = g['name'].toString();
                  return _buildSidebarItem(
                    icon: Icons.category_rounded,
                    title: name,
                    valueKey: 'genre-$id',
                    isDrawer: isDrawer,
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required String valueKey,
    required bool isDrawer,
  }) {
    final isSelected = _selectedFilterKey == valueKey;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.acentoMagenta.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.acentoMagenta.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.acentoMagenta.withValues(alpha: 0.1),
                    blurRadius: 8,
                  )
                ]
              : [],
        ),
        child: ListTile(
          onTap: () {
            _handleFilterChanged(valueKey);
            if (isDrawer) {
              Navigator.pop(context); // Close drawer if sliding
            }
          },
          leading: Icon(
            icon,
            color: isSelected ? AppColors.acentoMagenta : AppColors.textoSecundario,
            size: 20,
          ),
          title: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: isSelected ? AppColors.textoPrincipal : AppColors.textoSecundario,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_rounded, color: AppColors.acentoMagenta),
            const SizedBox(width: 10),
            const Text(
              'MIS PELÍCULAS FAVORITAS',
              style: TextStyle(
                color: AppColors.textoPrincipal,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_favorites.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Text(
                'No has agregado películas a tus favoritos.',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 340,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final movie = _favorites[index];
              return _MovieCard(
                movie: movie,
                onTap: () => _openDetails(movie),
              );
            },
          ),
      ],
    );
  }

  Widget _buildWatchLaterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bookmark_rounded, color: AppColors.acentoMagenta),
            const SizedBox(width: 10),
            const Text(
              'VER MÁS TARDE',
              style: TextStyle(
                color: AppColors.textoPrincipal,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_watchLater.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Text(
                'No has agregado películas a tu lista de ver más tarde.',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 340,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: _watchLater.length,
            itemBuilder: (context, index) {
              final movie = _watchLater[index];
              return _MovieCard(
                movie: movie,
                onTap: () => _openDetails(movie),
              );
            },
          ),
      ],
    );
  }

  Widget _buildGenreResultsSection() {
    final genreIdStr = _selectedFilterKey.substring(6);
    final genreId = int.tryParse(genreIdStr);
    final genreName = _genres.firstWhere((g) => g['id'] == genreId, orElse: () => {'name': ''})['name'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category_rounded, color: AppColors.acentoMagenta),
            const SizedBox(width: 10),
            Text(
              'GÉNERO: ${genreName.toString().toUpperCase()}',
              style: const TextStyle(
                color: AppColors.textoPrincipal,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_isLoadingGenreMovies)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: CircularProgressIndicator(color: AppColors.acentoMagenta),
            ),
          )
        else if (_genreMovies.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Text(
                'No se encontraron películas de este género.',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ),
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 340,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: _genreMovies.length,
            itemBuilder: (context, index) {
              final movie = _genreMovies[index];
              return _MovieCard(
                movie: movie,
                onTap: () => _openDetails(movie),
              );
            },
          ),
          if (_isLoadingMoreGenre)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.acentoMagenta),
              ),
            ),
        ],
      ],
    );
  }


  Widget _buildDetailsOverlay() {
    final movie = _selectedMovie!;
    final posterPath = movie['poster_path'];
    final backdropPath = movie['backdrop_path'];
    final title = movie['title'] ?? 'Sin título';
    final releaseDate = movie['release_date'] ?? 'N/A';
    final year = releaseDate.toString().split('-').first;
    final voteAverage = movie['vote_average'] ?? 0.0;
    final voteCount = movie['vote_count'] ?? 0;
    final overview = movie['overview'] ?? 'Sin sinopsis disponible.';

    final isFavorite = _favorites.any((m) => m['id'] == movie['id']);
    final isWatchLater = _watchLater.any((m) => m['id'] == movie['id']);

    return Positioned.fill(
      child: GestureDetector(
        onTap: _closeDetails,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {}, // Evita cerrar al hacer clic adentro
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 650,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.25),
                      blurRadius: 35,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.fondoBase.withValues(alpha: 0.95),
                      border: Border.all(
                        color: AppColors.acentoVioleta.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Banner Backdrop Image or YouTube Player
                          Stack(
                            children: [
                              if (_currentTrailerKey != null)
                                Container(
                                  height: 300,
                                  color: Colors.black,
                                  child: HtmlElementView(viewType: 'youtube-$_currentTrailerKey'),
                                )
                              else if (backdropPath != null)
                                Image.network(
                                  ApiService.getProxyImageUrl(backdropPath, 'w780'),
                                  height: 240,
                                  width: double.infinity,
                                  fit: BoxFit.fitWidth,
                                  errorBuilder: (_, __, ___) => Container(height: 240, color: Colors.purple.withValues(alpha: 0.1)),
                                )
                              else
                                Container(
                                  height: 240,
                                  color: Colors.purple.withValues(alpha: 0.05),
                                  child: const Center(
                                    child: Icon(Icons.movie_creation_outlined, color: AppColors.textoSecundario, size: 64),
                                  ),
                                ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                                  child: IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                                    onPressed: _closeDetails,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Details Container
                          Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Mini Poster
                                    if (posterPath != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          ApiService.getProxyImageUrl(posterPath, 'w500'),
                                          height: 140,
                                          width: 95,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            height: 140,
                                            width: 95,
                                            color: Colors.purple.withValues(alpha: 0.1),
                                            child: const Icon(
                                              Icons.movie_creation_outlined,
                                              color: AppColors.textoSecundario,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title.toUpperCase(),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: AppColors.textoPrincipal,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              // Mini trailer button right in the title row
                                              if (_isLoadingDetails)
                                                const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(color: AppColors.acentoMagenta, strokeWidth: 2),
                                                )
                                              else if (_fetchedTrailerKey != null && _currentTrailerKey == null)
                                                FuturisticButton(
                                                  text: 'Trailer',
                                                  icon: Icons.play_circle_outline_rounded,
                                                  onPressed: () {
                                                    final trailerKey = _fetchedTrailerKey!;
                                                    final viewType = 'youtube-$trailerKey';
                                                    ui_web.platformViewRegistry.registerViewFactory(
                                                      viewType,
                                                      (int viewId) {
                                                        final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
                                                        iframe.width = '100%';
                                                        iframe.height = '100%';
                                                        iframe.style.width = '100%';
                                                        iframe.style.height = '100%';
                                                        iframe.src = 'https://www.youtube.com/embed/$trailerKey?autoplay=1&rel=0';
                                                        iframe.style.border = 'none';
                                                        iframe.allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
                                                        iframe.setAttribute('allowfullscreen', 'true');
                                                        return iframe;
                                                      },
                                                    );
                                                    setState(() {
                                                      _currentTrailerKey = trailerKey;
                                                    });
                                                  },
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Año: $year  |  Votos: $voteCount',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.textoSecundario,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Rating indicator and toggles
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                              const SizedBox(width: 6),
                                              Text(
                                                voteAverage.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  color: AppColors.textoPrincipal,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Text(
                                                ' / 10',
                                                style: TextStyle(
                                                  color: AppColors.textoSecundario,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              _buildDetailsActionIcon(
                                                icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                color: isFavorite ? AppColors.acentoMagenta : AppColors.textoSecundario,
                                                tooltip: isFavorite ? 'Quitar de Favoritos' : 'Agregar a Favoritos',
                                                onTap: () => _toggleFavorite(movie),
                                              ),
                                              const SizedBox(width: 10),
                                              _buildDetailsActionIcon(
                                                icon: isWatchLater ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                                color: isWatchLater ? AppColors.acentoMagenta : AppColors.textoSecundario,
                                                tooltip: isWatchLater ? 'Quitar de Ver Más Tarde' : 'Guardar para Ver Más Tarde',
                                                onTap: () => _toggleWatchLater(movie),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  'SINOPSIS',
                                  style: TextStyle(
                                    color: AppColors.acentoMagenta,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  overview,
                                  style: const TextStyle(
                                    color: AppColors.textoSecundario,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                _buildStreamingPlatforms(),
                                _buildCastSection(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsActionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: color == AppColors.acentoMagenta
                  ? [
                      BoxShadow(
                        color: AppColors.acentoMagenta.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingPlatforms() {
    if (_isLoadingDetails) {
      return const SizedBox(
        height: 40,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.acentoMagenta, strokeWidth: 2))),
      );
    }
    
    final flatrateList = _watchProviders?['flatrate'] as List<dynamic>? ?? [];
    final seenNames = <String>{};
    final flatrate = flatrateList.where((provider) {
      final name = (provider['provider_name'] ?? '').toString().trim().toLowerCase();
      if (name.isEmpty) return false;
      return seenNames.add(name);
    }).toList();

    if (flatrate.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'DISPONIBLE EN',
          style: TextStyle(
            color: AppColors.acentoMagenta,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: flatrate.map((provider) {
            final logoPath = provider['logo_path'];
            final name = provider['provider_name'] ?? '';
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.acentoVioleta.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.acentoVioleta.withValues(alpha: 0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: logoPath != null
                        ? Image.network(
                            ApiService.getProxyImageUrl(logoPath, 'w92'),
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackProviderLogoMini(name),
                          )
                        : _buildFallbackProviderLogoMini(name),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFallbackProviderLogoMini(String name) {
    return Container(
      width: 24,
      height: 24,
      color: Colors.purple.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildCastSection() {
    if (_isLoadingDetails) {
      return const SizedBox(
        height: 60,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.acentoMagenta, strokeWidth: 2))),
      );
    }
    
    if (_cast.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final displayCast = _cast.take(15).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Text(
          'ELENCO PRINCIPAL',
          style: TextStyle(
            color: AppColors.acentoMagenta,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayCast.length,
            itemBuilder: (context, index) {
              final actor = displayCast[index];
              final name = actor['name'] ?? 'Desconocido';
              final character = actor['character'] ?? 'N/A';
              final profilePath = actor['profile_path'];
              
              return Container(
                width: 155,
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.acentoVioleta.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.acentoVioleta.withValues(alpha: 0.1),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: profilePath != null
                            ? Image.network(
                                ApiService.getProxyImageUrl(profilePath, 'w185'),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildFallbackCastAvatar(name),
                              )
                            : _buildFallbackCastAvatar(name),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textoPrincipal,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            character,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textoSecundario,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackCastAvatar(String name) {
    final initials = name.split(' ').map((e) => e.substring(0, 1)).take(2).join('').toUpperCase();
    return Container(
      width: 50,
      height: 50,
      color: Colors.purple.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'A',
          style: const TextStyle(
            color: AppColors.textoSecundario,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

}

class _MovieCard extends StatefulWidget {
  final Map<String, dynamic> movie;
  final VoidCallback onTap;

  const _MovieCard({required this.movie, required this.onTap});

  @override
  State<_MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<_MovieCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final posterPath = widget.movie['poster_path'];
    final title = widget.movie['title'] ?? 'Sin título';
    final voteAverage = widget.movie['vote_average'] ?? 0.0;
    final releaseDate = widget.movie['release_date'] ?? '';
    final year = releaseDate.toString().split('-').first;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Container(
            width: 175,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered ? AppColors.acentoMagenta : AppColors.acentoVioleta.withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppColors.acentoMagenta.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.white.withValues(alpha: 0.015),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Poster Image
                    Expanded(
                      child: posterPath != null
                          ? Image.network(
                              ApiService.getProxyImageUrl(posterPath, 'w500'),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const _PlaceholderPoster(),
                            )
                          : const _PlaceholderPoster(),
                    ),
                    // Titles and Ratings
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textoPrincipal,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                year.isNotEmpty ? year : 'N/A',
                                style: const TextStyle(
                                  color: AppColors.textoSecundario,
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.textoPrincipal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPoster extends StatelessWidget {
  const _PlaceholderPoster();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purple.withValues(alpha: 0.05),
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, color: AppColors.textoSecundario, size: 36),
      ),
    );
  }
}
