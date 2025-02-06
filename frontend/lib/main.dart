import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Topshur',
      theme: ThemeData(
        brightness: Brightness.dark, // Set dark theme
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black, // Set background to black
      ),
      home: DefaultTabController(
        length: 2, // Two tabs: Home and History
        child: AudioRecorderPage(),
      ),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

class AudioRecorderPage extends StatefulWidget {
  @override
  _AudioRecorderPageState createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage> {
  final record = Record();
  final audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _showMessage = false;
  String _recordingPath = '';
  DateTime? _recordingStartTime;
  Duration _recordingDuration = Duration.zero;
  final List<String> _recordings = [];

  @override
  void dispose() {
    record.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording) {
      await _stopRecording();
    }

    try {
      if (await record.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        String fileName = '${Uuid().v4()}.m4a';
        _recordingPath = '${tempDir.path}/$fileName';

        _recordingStartTime = DateTime.now();
        await record.start(
          path: _recordingPath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
        setState(() {
          _isRecording = true;
          _showMessage = false;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await record.stop();
      if (_recordingStartTime != null) {
        final recordingEndTime = DateTime.now();
        _recordingDuration = recordingEndTime.difference(_recordingStartTime!);
      }
      _recordings.add(_recordingPath);
      setState(() {
        _isRecording = false;
        _showMessage = true;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (!File(_recordingPath).existsSync()) {
      print('Recording file not found: $_recordingPath');
      return;
    }

    try {
      if (_isPlaying) {
        await audioPlayer.stop();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await audioPlayer.seek(Duration.zero);
        await audioPlayer.play(DeviceFileSource(_recordingPath));
        setState(() {
          _isPlaying = true;
        });
        audioPlayer.onPlayerComplete.listen((event) {
          setState(() {
            _isPlaying = false;
          });
        });
      }
    } catch (e) {
      print('Error playing recording: $e');
    }
  }

  Future<void> _deleteRecording(int index) async {
    final pathToDelete = _recordings[index];
    if (File(pathToDelete).existsSync()) {
      await File(pathToDelete).delete();
    }
    setState(() {
      _recordings.removeAt(index);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Topshur"),
      ),
      body: TabBarView(
        children: [
          // Home Tab Content
          _buildHomeTab(),
          // History Tab Content
          _buildHistoryTab(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding:
            const EdgeInsets.only(bottom: 16.0), // Added 16px bottom padding
        child: Container(
          color: Colors.black, // Dark background for the TabBar
          child: TabBar(
            labelColor: Colors.white, // White label text
            unselectedLabelColor: Colors.grey, // Grey for unselected tabs
            indicatorColor: Colors.blue, // Tab indicator color
            tabs: [
              Tab(text: 'Home'),
              Tab(text: 'History'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed:
                      File(_recordingPath).existsSync() ? _playRecording : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    minimumSize: Size(130, 50),
                  ),
                  child: Text(
                    'Play',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Convert Button (for future logic)
                ElevatedButton(
                  onPressed: () {
                    // Add conversion logic here if needed in the future
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    minimumSize: Size(130, 50),
                  ),
                  child: Text(
                    'Convert',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final reverseIndex = _recordings.length - 1 - index;
        final path = _recordings[reverseIndex];
        final isCurrentPlaying = _isPlaying && _recordingPath == path;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              title: Text(
                'Recording ${reverseIndex + 1}',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isCurrentPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if (isCurrentPlaying) {
                        await audioPlayer.stop();
                        setState(() {
                          _isPlaying = false;
                        });
                      } else {
                        await audioPlayer.stop();
                        await audioPlayer.seek(Duration.zero);
                        await audioPlayer.play(DeviceFileSource(path));
                        setState(() {
                          _isPlaying = true;
                          _recordingPath = path;
                        });
                        audioPlayer.onPlayerComplete.listen((event) {
                          setState(() {
                            _isPlaying = false;
                          });
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () {
                      _deleteRecording(reverseIndex);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
