import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movie_night/theme/color_scheme.dart';
import '../../services/http_service.dart';
import '../../services/session_service.dart';
import '../../models/session.dart';

class ShareCodeScreen extends StatefulWidget {
  final String deviceId;
  final VoidCallback onStartSuccess;

  const ShareCodeScreen({
    super.key,
    required this.deviceId,
    required this.onStartSuccess,
  });

  @override
  ShareCodeScreenState createState() => ShareCodeScreenState();
}

class ShareCodeScreenState extends State<ShareCodeScreen> {
  String? _sessionCode;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  //Star a new session function
  Future<void> _startSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Session session = await HttpService().startSession(widget.deviceId);
      await SessionService.saveSessionId(session.sessionId);

      setState(() {
        _sessionCode = session.code.toString().padLeft(4, '0');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start session. Try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //Clipboard functionality
  void _copyCodeToClipboard() {
    if (_sessionCode != null) {
      Clipboard.setData(ClipboardData(text: _sessionCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Code copied to clipboard',
            style: TextStyle(),
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  //Start a session dialog UI
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: onPrimaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'New Vote',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              )
            else if (_sessionCode != null)
              Column(
                children: [
                  const Text(
                    'Share this code with your friend:',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  //Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _sessionCode!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        color: Colors.black,
                        tooltip: 'Copy Code',
                        onPressed: _copyCodeToClipboard,
                      ),
                    ],
                  ),
                ],
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: onErrorColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,

      //Button
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ),
        if (_sessionCode != null)
          ElevatedButton(
            onPressed: widget.onStartSuccess,
            child: const Text(
              'Start',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
