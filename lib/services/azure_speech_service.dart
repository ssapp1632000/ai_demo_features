import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AzureSpeechService {
  // TODO: Replace with your Azure Speech API key or use environment variable
  static const String _apiKey = String.fromEnvironment(
    'AZURE_SPEECH_KEY',
    defaultValue: 'YOUR_AZURE_API_KEY_HERE',
  );
  static const String _region = 'eastus';
  final AudioRecorder _recorder = AudioRecorder();
  String? _audioPath;
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final Directory tempDir =
            await getTemporaryDirectory();
        _audioPath =
            '${tempDir.path}/azure_speech_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 128000,
          ),
          path: _audioPath!,
        );
        _isRecording = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  Future<String?> stopRecordingAndConvert() async {
    if (!_isRecording || _audioPath == null) {
      return null;
    }
    try {
      await _recorder.stop();
      _isRecording = false;

      final File audioFile = File(_audioPath!);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found');
      }
      final audioBytes = await audioFile.readAsBytes();
      final result = await _recognizeSpeech(audioBytes);
      await audioFile.delete();
      return result;
    } catch (e) {
      print('Error converting speech: $e');
      _isRecording = false;
      if (_audioPath != null) {
        try {
          await File(_audioPath!).delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  String _correctCommonMisrecognitions(String transcript) {
    String corrected = transcript;

    final corrections = {
      'bengali': 'Binghatti',
      'Benghazi': 'Binghatti',
    };

    corrections.forEach((wrong, correct) {
      final regex = RegExp(
        r'\b' + wrong + r'\b',
        caseSensitive: false,
      );
      corrected = corrected.replaceAllMapped(regex, (
        match,
      ) {
        final matched = match.group(0)!;
        if (matched[0] == matched[0].toUpperCase()) {
          return correct;
        }
        return correct.toLowerCase();
      });
    });

    return corrected;
  }

  Future<String?> _recognizeSpeech(
    List<int> audioBytes,
  ) async {
    final String endpoint =
        'https://$_region.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1';
    try {
      final response = await http.post(
        Uri.parse(endpoint).replace(
          queryParameters: {
            'language': 'en-US',
            'format': 'detailed',
            'profanity': 'masked',
          },
        ),
        headers: {
          'Ocp-Apim-Subscription-Key': _apiKey,
          'Content-Type':
              'audio/wav; codecs=audio/pcm; samplerate=16000',
          'Accept': 'application/json',
          'Connection': 'Keep-Alive',
          'Transfer-Encoding': 'chunked',
          'Expect': '100-continue',
        },
        body: audioBytes,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          response.body,
        );

        String? transcript;

        if (data.containsKey('DisplayText')) {
          transcript = data['DisplayText'] as String;
        } else if (data.containsKey('NBest') &&
            (data['NBest'] as List).isNotEmpty) {
          final bestResult = (data['NBest'] as List)[0];
          transcript = bestResult['Display'] as String;
        }

        // Apply post-processing corrections
        if (transcript != null && transcript.isNotEmpty) {
          transcript = _correctCommonMisrecognitions(
            transcript,
          );
        }

        return transcript;
      } else if (response.statusCode == 401) {
        throw Exception(
          'Invalid API key. Please check your Azure subscription key.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access forbidden. Check your Azure region and subscription.',
        );
      } else {
        print(
          'Azure API Error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to recognize speech: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Azure Speech API error: $e');
      rethrow;
    }
  }

  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;

      if (_audioPath != null) {
        try {
          await File(_audioPath!).delete();
        } catch (_) {}
      }
    }
  }

  static bool isConfigured() {
    return _apiKey != 'YOUR_AZURE_API_KEY_HERE' &&
        _apiKey.isNotEmpty;
  }

  void dispose() {
    _recorder.dispose();
  }
}
