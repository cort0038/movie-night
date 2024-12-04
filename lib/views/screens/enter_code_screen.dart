import 'package:flutter/material.dart';
import 'package:movie_night/theme/color_scheme.dart';
import '../../services/http_service.dart';
import '../../services/session_service.dart';
import '../../models/session.dart';

class EnterCodeScreen extends StatefulWidget {
  final String deviceId;
  final VoidCallback onJoinSuccess;

  const EnterCodeScreen({
    super.key,
    required this.deviceId,
    required this.onJoinSuccess,
  });

  @override
  EnterCodeScreenState createState() => EnterCodeScreenState();
}

class EnterCodeScreenState extends State<EnterCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  //Join a session function
  Future<void> _joinSession() async {
    final codeStr = _codeController.text.trim();

    if (codeStr.length != 4 || int.tryParse(codeStr) == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please enter a 4-digit code.';
      });
      return;
    }

    final int code = int.parse(codeStr);

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Session session =
          await HttpService().joinSession(widget.deviceId, code);
      await SessionService.saveSessionId(session.sessionId);

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onJoinSuccess();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to join session. Try a new code.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //Join a session dialog UI
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: onSecondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Join a Session',
        style: TextStyle(
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
            const Text(
              'Enter the code shared by your friend',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '----',
                hintStyle: TextStyle(
                  color: Colors.black54,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: onErrorColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,

      //Buttons
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
        ElevatedButton(
          onPressed: _isLoading ? null : _joinSession,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text(
                  "Let's begin",
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
