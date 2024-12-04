class VoteResponse {
  final String message;
  final int movieId;
  final bool match;
  final int numDevices;
  final int submittedMovie;

  VoteResponse({
    required this.message,
    required this.movieId,
    required this.match,
    required this.numDevices,
    required this.submittedMovie,
  });

  factory VoteResponse.fromJson(Map<String, dynamic> json) {
    return VoteResponse(
      message: json['message']?.toString() ?? 'No message provided.',
      movieId: _parseStringToInt(json['movie_id']),
      match: json['match'] ?? false,
      numDevices: json['num_devices'] ?? 0,
      submittedMovie: _parseStringToInt(json['submitted_movie']),
    );
  }

  static int _parseStringToInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    } else {
      return 0;
    }
  }
}
