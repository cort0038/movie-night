import 'dart:async';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:movie_night/theme/color_scheme.dart';
import 'package:swipe_cards/swipe_cards.dart';
import '../../services/http_service.dart';
import '../../services/session_service.dart';
import '../../models/movie.dart';
import '../../models/vote.dart';
import '../widgets/movie_poster.dart';
import 'package:intl/intl.dart';

class MovieSelectionScreen extends StatefulWidget {
  final String deviceId;

  const MovieSelectionScreen(this.deviceId, {super.key});

  @override
  MovieSelectionScreenState createState() => MovieSelectionScreenState();
}

class MovieSelectionScreenState extends State<MovieSelectionScreen> {
  List<Movie> movies = [];
  int currentIndex = 0;
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  final List<SwipeItem> _swipeItems = [];
  MatchEngine? _matchEngine;

  bool _showHeart = false;
  bool _showX = false;
  Timer? _iconTimer;

  @override
  void initState() {
    super.initState();
    _matchEngine = MatchEngine(swipeItems: _swipeItems);
    _fetchMovies();
  }

  //Using fetchMovies method from "services/http_service.dart"
  Future<void> _fetchMovies() async {
    if (isLoading || !hasMore) return;
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final List<Movie> newMovies =
          await HttpService().fetchMovies(currentPage);
      if (!mounted) return;

      setState(() {
        if (newMovies.isEmpty) {
          hasMore = false;
        } else {
          movies.addAll(newMovies);
          currentPage++;
          _initializeSwipeItems(newMovies);
        }
      });
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackbar('Failed to load movies: $error');
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  //Using voteMovie method from "services/http_service.dart"
  Future<void> _voteMovie(Movie movie, bool vote) async {
    try {
      final String? sessionId = await SessionService.getSessionId();

      if (!mounted) return;
      if (sessionId == null) throw Exception('Session ID is missing');

      final VoteResponse response = await HttpService().voteMovie(
        sessionId,
        movie.id,
        vote,
      );

      if (!mounted) return;

      bool match = response.match;
      final int matchedMovieId = response.movieId;

      if (response.numDevices <= 1) {
        match = false;
      }

      if (match) {
        final Movie? matchedMovie = movies.firstWhereOrNull(
          (m) => m.id == matchedMovieId,
        );

        if (matchedMovie != null) {
          _showMatchDialog(matchedMovie);
        } else {
          _advanceToNextMovie();
        }
      }
    } catch (error) {
      if (!mounted) return;
    }
  }

  //Passing the movies to the swipeItems list
  void _initializeSwipeItems(List<Movie> newMovies) {
    _swipeItems.addAll(newMovies.map((movie) {
      return SwipeItem(
        content: movie,
        likeAction: () {
          _voteMovie(movie, true);
          _showSwipeIcon(true);
          _advanceToNextMovie();
        },
        nopeAction: () {
          _voteMovie(movie, false);
          _showSwipeIcon(false);
          _advanceToNextMovie();
        },
      );
    }).toList());

    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  //Showing the swipe icon
  void _showSwipeIcon(bool isLike) {
    _iconTimer?.cancel();

    setState(() {
      _showHeart = isLike;
      _showX = !isLike;
    });

    _iconTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _showHeart = false;
        _showX = false;
      });
    });
  }

  //Advance to the next movie
  void _advanceToNextMovie() {
    if (!mounted) return;
    setState(() {
      currentIndex++;
    });
    if (currentIndex == movies.length && hasMore) {
      _fetchMovies();
    }
  }

  //Showing error messages
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  //Showing the match dialog
  void _showMatchDialog(Movie movie) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'It\'s a Match!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: movie.posterPath != null
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                        height: 300,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/default_poster.png',
                        height: 300,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                movie.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star,
                      color: Color.fromARGB(255, 0, 165, 63), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "Rating: ${movie.voteAverage.toStringAsFixed(1)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                movie.overview,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  //Movie Selection Swipe UI
  Widget build(BuildContext context) {
    //Loading movie
    if (movies.isEmpty && isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    //No movies
    if (movies.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'No movies available. Please try again later.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    //App Bar
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Movie Night',
          style: TextStyle(
            fontFamily: 'Protest Revolution',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 125, 239, 129),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          //Swipeable Area
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //Top description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Swipe right to like or left to dislike.\nLet\'s find a movie match!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    //Stacked cards
                    if (currentIndex + 1 < movies.length)
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.25,
                        child: _buildUpcomingMoviePreview(),
                      ),
                    _matchEngine != null && _swipeItems.isNotEmpty
                        //Swipe card - current movie
                        ? SwipeCards(
                            matchEngine: _matchEngine!,
                            itemBuilder: (BuildContext context, int index) {
                              final Movie movie =
                                  _swipeItems[index].content as Movie;
                              return Center(
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: MoviePoster(
                                                posterPath: movie.posterPath),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            movie.title,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Color.fromARGB(
                                                    255, 0, 165, 63),
                                                size: 18,
                                              ),
                                              const Text(
                                                'Rating:',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                movie.voteAverage
                                                    .toStringAsFixed(1),
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "Release on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(movie.releaseDate))}",
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            onStackFinished: () {
                              setState(() {
                                currentIndex = movies.length;
                              });
                              if (hasMore) {
                                _fetchMovies();
                              }
                            },
                            upSwipeAllowed: false,
                            fillSpace: false,
                          )
                        : const Center(
                            child: Text(
                              'No more movies to display.',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),

          //Swipe Icons
          if (_showHeart)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.black,
                  size: 50,
                ),
              ),
            ),
          if (_showX)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: onErrorColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.black,
                  size: 50,
                ),
              ),
            ),
        ],
      ),
    );
  }

  //Upcoming movie preview stack
  Widget _buildUpcomingMoviePreview() {
    if (currentIndex + 1 >= movies.length) {
      return Container();
    }

    final Movie upcomingMovie = movies[currentIndex + 1];

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      height: MediaQuery.of(context).size.width * 1.05,
      child: Opacity(
        opacity: 0.7,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: Colors.grey[850],
          elevation: 5,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: upcomingMovie.posterPath != null
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w300${upcomingMovie.posterPath}',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Image.asset(
                          'assets/images/default_poster.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text(
                  upcomingMovie.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _iconTimer?.cancel();
    super.dispose();
  }
}
