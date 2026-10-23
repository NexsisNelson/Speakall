# Speakall

Speakall is a Flutter language-practice app for speaking English and viewing Chinese translations. It combines speech recognition, translation, text-to-speech, and an animated listening orb.

## Features

- Capture spoken English from the home screen and open the translation screen with the recognized sentence.
- View live speech recognition results and translate completed or paused phrases into Simplified Chinese.
- Hear the English or Chinese text with text-to-speech.
- Copy recognized text or translations to the clipboard.
- See the animated orb and microphone indicate when speech recognition is active.

## Requirements

- Flutter and Dart versions compatible with the SDK constraint in [`pubspec.yaml`](./pubspec.yaml).
- A device or emulator with a speech-recognition service for microphone features.
- Internet access for translation.

## Run locally

```bash
flutter pub get
flutter run
```

To run the checks:

```bash
flutter analyze
flutter test
```

## Microphone permissions

The required platform declarations are included in the project:

- **Android:** `RECORD_AUDIO` and `INTERNET` permissions, plus a speech-recognition service query, are declared in `android/app/src/main/AndroidManifest.xml`.
- **iOS:** microphone and speech-recognition usage descriptions are declared in `ios/Runner/Info.plist`.

Grant microphone access when prompted. Speech recognition availability and behavior depend on the device, operating system, and installed recognition services.

## Using the app

1. Tap **Get Started** to open the home screen.
2. Tap the microphone and speak an English sentence. When recognition finishes, the app opens the translation screen with the recognized text and starts translating it.
3. On the translation screen, tap the microphone to dictate another phrase. Partial results are translated after a short pause; final results are translated immediately.
4. Use the speaker and copy buttons beneath each text section to listen or copy its text.

## Packages

- [`speech_to_text`](https://pub.dev/packages/speech_to_text) for speech recognition.
- [`translator`](https://pub.dev/packages/translator) for English-to-Chinese translation.
- [`flutter_tts`](https://pub.dev/packages/flutter_tts) for speech playback.
