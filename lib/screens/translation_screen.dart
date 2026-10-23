import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key, this.initialEnglish});

  final String? initialEnglish;

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GoogleTranslator _translator = GoogleTranslator();

  bool _isListening = false;
  bool _isTranslating = false;
  bool _speechAvailable = false;
  String _englishText = '';
  String _chineseText = '';
  Timer? _debounce;
  int _translationRequest = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeSpeech());
    final initialEnglish = widget.initialEnglish?.trim();
    if (initialEnglish != null && initialEnglish.isNotEmpty) {
      _englishText = initialEnglish;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_translateText(initialEnglish));
      });
    }
  }

  Future<void> _speak(String text, String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.setPitch(1);
    await _flutterTts.speak(text);
  }

  Future<void> _initializeSpeech() async {
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

      if (mounted) {
        setState(() => _speechAvailable = available);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _speechAvailable = false);
      _showMessage('Could not initialize speech recognition: $error');
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      _debounce?.cancel();
      final text = _englishText.trim();
      if (text.isNotEmpty) unawaited(_translateText(text));
      return;
    }

    if (!_speechAvailable) {
      await _initializeSpeech();
    }
    if (!_speechAvailable || !mounted) {
      if (mounted) _showMessage('Speech recognition is unavailable.');
      return;
    }

    setState(() {
      _isListening = true;
      _englishText = '';
    });

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: 'en_US',
          partialResults: true,
        ),
        onResult: (result) {
          if (!mounted) return;
          final text = result.recognizedWords.trim();
          setState(() => _englishText = result.recognizedWords);
          _debounce?.cancel();
          if (text.isEmpty) return;

          if (result.finalResult) {
            unawaited(_translateText(text));
          } else {
            _debounce = Timer(const Duration(milliseconds: 1500), () {
              if (mounted) unawaited(_translateText(text));
            });
          }
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isListening = false);
      _showMessage('Could not start speech recognition: $error');
    }
  }

  Future<void> _translateText(String text) async {
    final request = ++_translationRequest;
    setState(() => _isTranslating = true);
    try {
      final translation = await _translator.translate(
        text,
        from: 'en',
        to: 'zh-cn',
      );
      if (!mounted || request != _translationRequest) return;
      setState(() => _chineseText = translation.text);
    } catch (error) {
      if (!mounted || request != _translationRequest) return;
      _showMessage('Translation failed: $error');
    } finally {
      if (mounted && request == _translationRequest) {
        setState(() => _isTranslating = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_speech.cancel());
    unawaited(_flutterTts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {}),
          IconButton(icon: const Icon(Icons.star_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSectionHeader('English'),
                  _buildMessage(_englishText, 'en-US'),
                  const Divider(height: 40, color: Colors.transparent),
                  _buildSectionHeader('Chinese'),
                  _buildMessage(_chineseText, 'zh-CN'),
                  if (_isTranslating) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bottomAction(Icons.translate, 'Translate'),
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
                  _bottomAction(Icons.camera_alt, 'Camera'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessage(String text, String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionButton(Icons.volume_up, () => _speak(text, languageCode)),
            const SizedBox(width: 12),
            _actionButton(Icons.copy, () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              }
            }),
            const Spacer(),
            _actionButton(Icons.more_horiz, () {}),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: Colors.black54),
        onPressed: onTap,
      ),
    );
  }

  Widget _bottomAction(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: Icon(icon, color: Colors.black),
            onPressed: () {},
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
