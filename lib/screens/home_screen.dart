import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../widgets/speaking_orb.dart';
import 'translation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _handoffInProgress = false;

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _isListening = false);
          _showMessage('Speech recognition error: ${error.errorMsg}');
        },
      );
      if (!available) {
        if (mounted) {
          _showMessage('Speech recognition is unavailable on this device.');
        }
        return;
      }
      if (!mounted) return;

      _handoffInProgress = false;
      setState(() => _isListening = true);
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: 'en_US',
          partialResults: true,
        ),
        onResult: (result) {
          final transcript = result.recognizedWords.trim();
          if (!result.finalResult ||
              transcript.isEmpty ||
              _handoffInProgress ||
              !mounted) {
            return;
          }

          _handoffInProgress = true;
          unawaited(_handoffTranscript(transcript));
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isListening = false);
      _showMessage('Could not start speech recognition: $error');
    }
  }

  Future<void> _handoffTranscript(String transcript) async {
    try {
      await _speech.stop();
    } catch (error) {
      if (mounted) _showMessage('Could not stop speech recognition: $error');
    }
    if (!mounted) return;
    setState(() => _isListening = false);
    _openTranslation(context, initialEnglish: transcript);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleAction(icon: Icons.menu, onPressed: () {}),
                  _CircleAction(icon: Icons.history, onPressed: () {}),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpeakingOrb(
                    isListening: _isListening,
                    size: MediaQuery.sizeOf(context).height < 700 ? 180 : 240,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isListening ? 'Listening...' : "Let's Speak English",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isListening
                        ? 'Speak now'
                        : 'Your personal AI language partner',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const _TranslateCard(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BottomAction(
                    icon: Icons.translate,
                    label: 'Translate',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const TranslationScreen(),
                        ),
                      );
                    },
                  ),
                  FloatingActionButton(
                    onPressed: _toggleListening,
                    backgroundColor: _isListening ? Colors.red : Colors.black,
                    shape: const CircleBorder(),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  _BottomAction(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _openTranslation(BuildContext context, {String? initialEnglish}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TranslationScreen(initialEnglish: initialEnglish),
      ),
    );
  }
}

class _TranslateCard extends StatefulWidget {
  const _TranslateCard();

  @override
  State<_TranslateCard> createState() => _TranslateCardState();
}

class _TranslateCardState extends State<_TranslateCard> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _languageChip('???? English'),
              const SizedBox(width: 8),
              const Icon(Icons.swap_horiz, color: Colors.grey),
              const SizedBox(width: 8),
              _languageChip('???? Chinese'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Write your text here...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.black,
                child: IconButton(
                  tooltip: 'Open conversation',
                  icon: const Icon(Icons.mic, color: Colors.white),
                  onPressed: () => _HomeScreenState._openTranslation(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _languageChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onPressed,
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: Icon(icon, color: Colors.black),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
