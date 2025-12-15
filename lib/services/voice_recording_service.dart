import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Check if microphone permission is granted
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission first
      if (!await checkPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          print('Microphone permission denied');
          return false;
        }
      }

      // Check if already recording
      if (_isRecording) {
        print('Already recording');
        return false;
      }

      // Generate file path
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_command_$timestamp.m4a';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      print('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        print('Not currently recording');
        return null;
      }

      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null && File(path).existsSync()) {
        print('Recording stopped: $path');
        return path;
      } else {
        print('Recording file not found');
        return null;
      }
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel current recording without saving
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;

        // Delete the file if it exists
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (file.existsSync()) {
            await file.delete();
            print('Recording cancelled and file deleted');
          }
        }
      }
    } catch (e) {
      print('Error cancelling recording: $e');
    }
  }

  /// Get all saved recordings
  Future<List<String>> getSavedRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);

      final recordings = dir
          .listSync()
          .where((item) =>
              item is File &&
              item.path.contains('voice_command_') &&
              item.path.endsWith('.m4a'))
          .map((item) => item.path)
          .toList();

      // Sort by date (newest first)
      recordings.sort((a, b) => b.compareTo(a));

      return recordings;
    } catch (e) {
      print('Error getting saved recordings: $e');
      return [];
    }
  }

  /// Delete a recording file
  Future<bool> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
        print('Recording deleted: $path');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting recording: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _audioRecorder.dispose();
  }
}
