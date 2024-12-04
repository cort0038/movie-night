import 'dart:math';
import 'package:flutter/material.dart';
import 'package:movie_night/theme/color_scheme.dart';
import 'package:platform_device_id/platform_device_id.dart';
import '../../services/http_service.dart';
import '../../models/movie.dart';
import 'movie_selection_screen.dart';
import 'enter_code_screen.dart';
import 'share_code_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? deviceId;
  List<Movie> _movies = [];
  bool _isLoadingMovies = false;
  String? _moviesError;

  @override
  void initState() {
    super.initState();
    _fetchDeviceId();
    _fetchRandomMovies();
  }

  //Get device ID function
  Future<void> _fetchDeviceId() async {
    final id = await PlatformDeviceId.getDeviceId;

    setState(() {
      deviceId = id;
    });
  }

  //Fetch random movies function
  Future<void> _fetchRandomMovies() async {
    setState(() {
      _isLoadingMovies = true;
      _moviesError = null;
    });

    try {
      List<Movie> fetchedMovies = [];

      for (int page = 1; page <= 2; page++) {
        List<Movie> moviesPage = await HttpService().fetchMovies(page);
        fetchedMovies.addAll(moviesPage);
      }

      if (fetchedMovies.isEmpty) {
        throw Exception('No movies found.');
      }

      fetchedMovies.shuffle(Random());
      List<Movie> randomMovies = fetchedMovies.take(10).toList();

      setState(() {
        _movies = randomMovies;
      });
    } catch (e) {
      setState(() {
        _moviesError = 'Failed to load movies. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoadingMovies = false;
      });
    }
  }

  //Call the "ShareCodeScreen" class to show modal
  void _showStartVoteModal(BuildContext context) {
    if (deviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fetching device ID. Please wait...'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ShareCodeScreen(
          deviceId: deviceId!,
          onStartSuccess: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieSelectionScreen(deviceId!),
              ),
            );
          },
        );
      },
    );
  }

  //Call the "EnterCodeScreen" class to show modal
  void _showJoinVoteModal(BuildContext context) {
    if (deviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fetching device ID. Please wait...'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return EnterCodeScreen(
          deviceId: deviceId!,
          onJoinSuccess: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieSelectionScreen(deviceId!),
              ),
            );
          },
        );
      },
    );
  }

  @override
  //Welcome screen UI
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      //App bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Movie Night',
          style: TextStyle(
            fontFamily: 'Protest Revolution',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        centerTitle: true,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 48,
                  left: 16,
                  right: 16,
                  bottom: max(16, constraints.maxHeight - 500),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    const Text(
                      "What do you want to watch today?\nLet's decide together! 🍿",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Start a session button
                    GestureDetector(
                      onTap: () {
                        _showStartVoteModal(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: onPrimaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.thumb_up, color: Colors.black),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start a session',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Start a new voting round with your friends',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Join a session button
                    GestureDetector(
                      onTap: () {
                        _showJoinVoteModal(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: onSecondaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.group, color: Colors.black),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Join a session',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    )),
                                Text(
                                  'Ask your friend for a code to join a room',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Hot movies carousel
                    const Text(
                      'Hot Movies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoadingMovies
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : _moviesError != null
                            ? Center(
                                child: Text(
                                  _moviesError!,
                                  style: const TextStyle(
                                    color: onErrorColor,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : SizedBox(
                                height: 250,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _movies.length,
                                  itemBuilder: (context, index) {
                                    return _buildMovieCard(_movies[index]);
                                  },
                                ),
                              ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  //Movie card widget
  Widget _buildMovieCard(Movie movie) {
    const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              height: 180,
              width: 120,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: movie.posterPath != null
                      ? NetworkImage('$imageBaseUrl${movie.posterPath}')
                      : const AssetImage('assets/images/default_poster.png')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: Text(
                movie.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 14),
                const SizedBox(width: 4),
                Text(
                  movie.voteAverage.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
