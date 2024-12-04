import 'package:flutter/material.dart';

class MoviePoster extends StatelessWidget {
  final String? posterPath;

  const MoviePoster({this.posterPath, super.key});

  @override
  Widget build(BuildContext context) {
    if (posterPath == null || posterPath!.isEmpty) {
      return Image.asset(
        'assets/images/default_poster.png',
        height: 300,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      'https://image.tmdb.org/t/p/w500$posterPath',
      errorBuilder: (_, __, ___) =>
          Image.asset('assets/images/default_poster.png'),
      fit: BoxFit.cover,
    );
  }
}
