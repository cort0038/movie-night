class Session {
  final String message;
  final int? code;
  final String sessionId;

  Session({
    required this.message,
    this.code,
    required this.sessionId,
  });

  factory Session.fromJson(Map<String, dynamic> data) {
    return Session(
      message: data['message']?.toString() ?? 'No message provided.',
      code: data['code'] is int
          ? data['code']
          : data['code'] is String
              ? int.tryParse(data['code'])
              : null,
      sessionId: data['session_id']?.toString() ?? 'UnknownSessionID',
    );
  }
}
