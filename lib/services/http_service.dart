import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/session.dart';
import '../models/vote.dart';

class HttpService {
  final String movieNightApiUrl = 'https://movie-night-api.onrender.com';
  final String tmdbApiKey = 'a948ce29db1844d126091636b22b38a6';
  final String tmdbBaseUrl = 'https://api.themoviedb.org/3/discover/movie';

  //Fetch movies service - https://developer.themoviedb.org/docs/getting-started
  Future<List<Movie>> fetchMovies(int page) async {
    /* EXAMPLE REPONSE:
      results: [
        {
        adult: false,
        backdrop_path:"/tElnmtQ6yz1PjN1kePNl8yMSb59.jpg",
        genre_ids: [16, 35, 10751, 12],
        id: 1241982,
        original_language: "en",
        original_title: "Moana 2",
        overview: "After receiving an unexpected call from her wayfinding ancestors...",
        popularity: 6947.74,
        poster_path: "/yh64qw9mgXBvlaWDi7Q9tpUBAvH.jpg",
        release_date: "2024-11-27",
        title: "Moana 2",
        video: false,
        vote_average: 7,
        vote_count: 262
        }
      ]  
    */

    final url =
        '$tmdbBaseUrl?include_adult=false&include_video=false&language=en-US&page=$page&sort_by=popularity.desc&api_key=$tmdbApiKey';
    debugPrint('fetchMovies URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['results'] == null || decoded['results'] is! List) {
          throw Exception(
              'Invalid API response: "results" not found or not a list.');
        }
        final results = decoded['results'] as List<dynamic>;
        return results
            .map<Movie>((movieJson) =>
                Movie.fromJson(movieJson as Map<String, dynamic>))
            .toList();
      } else {
        final errorMsg = 'Failed to fetch movies: ${response.statusCode}';
        debugPrint(errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('fetchMovies error: $e');
      rethrow;
    }
  }

  //Voting API service - https://movie-night-api.onrender.com
  Future<Map<String, dynamic>> _votingApi(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return data ?? {};
      } else {
        final errorMsg =
            'Failed API call: $url with status ${response.statusCode}';
        debugPrint(errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('_makeApiCall error: $e');
      rethrow;
    }
  }

  //Start a new session service
  Future<Session> startSession(String deviceId) async {
    /* GET /start-session [2]
      0: "requires {String device_id}"
      1: "returns {data: {String message, String session_id, String code }}" */

    final url = '$movieNightApiUrl/start-session?device_id=$deviceId';
    debugPrint('startSession URL: $url');

    try {
      final result = await _votingApi(url);
      return Session.fromJson(result);
    } catch (e) {
      debugPrint('startSession error: $e');
      rethrow;
    }
  }

  //Join a session service
  Future<Session> joinSession(String deviceId, int code) async {
    /* GET /join-session [2]
      0: "requires {String device_id, int code}"
      1: "returns {data: {String message, String session_id}}" */

    final url = '$movieNightApiUrl/join-session?device_id=$deviceId&code=$code';
    debugPrint('joinSession URL: $url');

    try {
      final data = await _votingApi(url);
      return Session.fromJson(data);
    } catch (e) {
      debugPrint('joinSession error: $e');
      throw Exception('Failed to join session: $e');
    }
  }

  //Vote movie service
  Future<VoteResponse> voteMovie(

      /* GET /vote-movie [2]
      0: "requires {String session_id, int movie_id, bool vote}"
      1: "returns {data: {String message, String movie_id, bool vote, int num_devices, String submitted_movie}}" */

      String sessionId,
      int movieId,
      bool vote) async {
    final url =
        '$movieNightApiUrl/vote-movie?session_id=$sessionId&movie_id=$movieId&vote=$vote';
    debugPrint('voteMovie URL: $url');

    try {
      final response = await http.get(Uri.parse(url));
      debugPrint('voteMovie HTTP response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        if (data == null) {
          throw Exception('voteMovie API response data is null.');
        }
        return VoteResponse.fromJson(data);
      } else {
        final errorMsg = 'Failed to submit vote: ${response.statusCode}';
        debugPrint(errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('voteMovie error: $e');
      rethrow;
    }
  }
}
