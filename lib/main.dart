import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/home_body.dart';
import 'widgets/background_wrapper.dart';
import 'widgets/dashboard_header.dart';
import 'pages/profile_page.dart';
import 'pages/directory_page.dart';
import 'package:ai_chat_sdk/ai_chat_sdk.dart';
import 'services/graphql_service.dart';
import 'services/azure_speech_service.dart';
import 'services/navigation_controller.dart';
import 'services/mock_navigation_backend.dart';
import 'services/ai_navigation_service.dart';
import 'theme_provider.dart';
import 'themes.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AI Demo',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          home: MainPage(),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  bool _isRecording = false;
  final AzureSpeechService _azureSpeech =
      AzureSpeechService();
  final TextEditingController _homeTextController =
      TextEditingController();
  final GlobalKey<DashboardHeaderState> _dashboardKey =
      GlobalKey<DashboardHeaderState>();

  // GlobalKeys for navigation control
  final GlobalKey _directoryKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Set demo token for API authentication
    const demoToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjIsImVtYWlsIjoibXVlaW4uZmFsbGFoYUBzaWx2ZXJzdG9uZWFyY2hpdGVjdHMuY29tIiwiaWF0IjoxNzYzNDQyNDQzLCJleHAiOjE3NjQwNDcyNDN9.GxZb_Tn7KV18wqqbT07IO4q4ta0wgZ6cZSuBGV3-VqY';
    GraphQLService.setToken(demoToken);

    // Check microphone permission
    _checkMicrophonePermission();
  }

  @override
  void dispose() {
    _homeTextController.dispose();
    _azureSpeech.dispose();
    super.dispose();
  }

  Future<void> _checkMicrophonePermission() async {
    // Request microphone permission
    var status = await Permission.microphone.request();

    if (!mounted) return;

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Microphone permission is required for voice input',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _startRecording() async {
    // Check if Azure is configured
    if (!AzureSpeechService.isConfigured()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Azure Speech Service not configured. Please add your API key.',
          ),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isRecording = true;
    });

    try {
      // Start recording with Azure Speech Service
      final started = await _azureSpeech.startRecording();

      if (!started) {
        throw Exception(
          'Failed to start recording. Check microphone permissions.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _stopRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
      });

      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                  ),
                ),
                SizedBox(width: 16),
                Text('Converting speech to text...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );

        // Stop recording and convert to text using Azure with custom vocabulary
        final transcript = await _azureSpeech
            .stopRecordingAndConvert();

        if (!mounted) return;

        // Hide loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (transcript != null && transcript.isNotEmpty) {
          setState(() {
            _homeTextController.text = transcript;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Voice converted to text successfully!',
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No speech detected. Please speak louder and try again.',
              ),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    // Refresh dashboard header data
    await _dashboardKey.currentState?.refresh();
  }

  // Get navigation controller with callbacks
  NavigationController _getNavigationController() {
    return NavigationController(
      context: context,
      onTabChange: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      onSubTabChange: (index) {
        // Handle sub-tab changes for Profile and Directory pages
        if (_currentIndex == 3) {
          // Profile page sub-tabs
          final profileState = _profileKey.currentState;
          if (profileState != null) {
            (profileState as dynamic).tabController
                .animateTo(index);
          }
        } else if (_currentIndex == 4) {
          // Directory page sub-tabs
          final directoryState = _directoryKey.currentState;
          if (directoryState != null) {
            (directoryState as dynamic).tabController
                .animateTo(index);
          }
        }
      },
      directoryPageKey: _directoryKey,
    );
  }

  // Execute test navigation commands
  void _executeTestNavigation(int testCase) {
    final response =
        MockNavigationBackend.getNavigationCommand(
          testCase,
        );
    final controller = _getNavigationController();
    controller.executeCommand(response);
  }

  // Handle AI navigation from text input
  Future<void> _handleAINavigation() async {
    final userText = _homeTextController.text.trim();

    // Validate input
    if (userText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Please enter a command'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            margin: EdgeInsets.all(50),
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Processing your request...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // Call AI backend
      final response = await AINavigationService.getNavigationCommand(userText);

      // Hide loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Execute navigation
      final controller = _getNavigationController();
      await controller.executeCommand(response);

      // Clear text field after successful execution
      _homeTextController.clear();
    } catch (e) {
      // Hide loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(e.toString().replaceFirst('Exception: ', '')),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    );
    final isDark = themeProvider.isDarkMode;
    return Drawer(
      child: Container(
        color: isDark
            ? AppColors.backgroundDark
            : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.accent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.settings,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Theme Toggle
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'Theme Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary
                      .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Set system UI overlay style for immersive status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: isDark
            ? Brightness.dark
            : Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(context),
      body: _currentIndex == 0
          ? BackgroundWrapper(
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // Dashboard Header
                        DashboardHeader(key: _dashboardKey),
                        // Original Home Content
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                                horizontal: 30.0,
                              ),
                          child: Column(
                            children: [
                              // Text field
                              TextField(
                                controller:
                                    _homeTextController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter your text here or use the mic button...',
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                          12,
                                        ),
                                  ),
                                  focusedBorder:
                                      OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                              12,
                                            ),
                                        borderSide:
                                            BorderSide(
                                              color: AppColors
                                                  .primary,
                                              width: 2,
                                            ),
                                      ),
                                  contentPadding:
                                      EdgeInsets.all(16),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // AI Navigation "Go" Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _handleAINavigation,
                                  icon: Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Go - Send to AI',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              // Navigation Test Buttons
                              Text(
                                'Navigation Test Cases',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Test Case 1: View Employee Reports
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _executeTestNavigation(
                                        1,
                                      ),
                                  icon: Icon(
                                    Icons.assessment,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Test 1: View Employee Reports',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.blue,
                                    padding:
                                        EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                            12,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Test Case 2: My Reports
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _executeTestNavigation(
                                        2,
                                      ),
                                  icon: Icon(
                                    Icons.analytics,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Test 2: My Reports',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.green,
                                    padding:
                                        EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                            12,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Test Case 3: Project Time Tracker
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _executeTestNavigation(
                                        3,
                                      ),
                                  icon: Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Test 3: Project Time Tracker',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.orange,
                                    padding:
                                        EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                            12,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : _currentIndex == 1
          ? BackgroundWrapper(
              child: SafeArea(
                child: HomeBody(
                  onSubmit: (text) {
                    print("Text Submitted: $text");
                  },
                  recognizedText: '',
                ),
              ),
            )
          : _currentIndex == 2
          ? SafeArea(
              child: AiChatScreen(
                theme: AiChatTheme.fromMaterialTheme(theme),
              ),
            )
          : _currentIndex == 3
          ? SafeArea(child: ProfilePage(key: _profileKey))
          : BackgroundWrapper(
              child: SafeArea(
                child: DirectoryPage(key: _directoryKey),
              ),
            ),
      floatingActionButton: _currentIndex == 0
          ? GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: _isRecording
                    ? AppColors.recording
                    : AppColors.primary,
                child: Icon(
                  Icons.mic,
                  color: AppColors.white,
                  size: 30,
                ),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_fields),
            label: 'Text Enhancement',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Directory',
          ),
        ],
      ),
    );
  }
}
