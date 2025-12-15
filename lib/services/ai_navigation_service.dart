import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for AI-powered navigation commands
///
/// This service communicates with an AI backend to convert natural language
/// commands into navigation steps that can be executed by the NavigationController.
class AINavigationService {
  // API Configuration
  static const String _baseUrl =
      'https://ai.ssapp.site';
  static const String _navigationEndpoint =
      '/api/v1/navigator/command';
  static const String _healthEndpoint = '/health';

  // Timeouts
  static const Duration _requestTimeout = Duration(
    minutes: 3,
  );
  static const Duration _healthCheckTimeout = Duration(
    seconds: 5,
  );

  // Error Messages
  static const String _timeoutError =
      'Request timeout - AI backend took too long to respond';
  static const String _invalidResponseError =
      'Invalid response: missing "steps" field';
  static const String _badRequestError =
      'Could not understand your request. Please try rephrasing.';
  static const String _notFoundError =
      'AI navigation endpoint not configured';
  static const String _serverError =
      'AI backend error. Please try again later.';
  static const String _connectionError =
      'Failed to connect to AI backend';

  /// Sends a natural language command to the AI backend
  ///
  /// Returns a map containing navigation steps to execute
  ///
  /// Throws an [Exception] if the request fails or times out
  static Future<Map<String, dynamic>> getNavigationCommand(
    String userText,
  ) async {
    try {
      print('🔵 [API] Sending command: $userText');
      final response = await _makeRequest(userText);
      print(
        '🟢 [API] Response received: Status ${response.statusCode}',
      );
      return _handleResponse(response);
    } catch (e) {
      print(
        '🔴 [API ERROR] Failed to get navigation command: $e',
      );
      if (e is Exception) rethrow;
      throw Exception('$_connectionError: $e');
    }
  }

  /// Checks if the AI backend is healthy and responsive
  ///
  /// Returns `true` if the backend is available, `false` otherwise
  static Future<bool> checkBackendHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$_healthEndpoint'))
          .timeout(_healthCheckTimeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Private helper methods

  /// Makes HTTP POST request to the AI backend
  static Future<http.Response> _makeRequest(
    String userText,
  ) {
    final requestBody = {
      'command': userText,
      'current_location': 'Home',
      'structure': _appStructure,
    };

    return http
        .post(
          Uri.parse('$_baseUrl$_navigationEndpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception(_timeoutError),
        );
  }

  /// Handles the HTTP response and extracts navigation data
  static Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    switch (response.statusCode) {
      case 200:
        return _parseSuccessResponse(response.body);
      case 400:
        throw Exception(_badRequestError);
      case 404:
        throw Exception(_notFoundError);
      case 500:
        throw Exception(_serverError);
      default:
        throw Exception(
          'Request failed with status: ${response.statusCode}',
        );
    }
  }

  /// Parses and validates successful response
  static Map<String, dynamic> _parseSuccessResponse(
    String responseBody,
  ) {
    final navigationCommand =
        jsonDecode(responseBody) as Map<String, dynamic>;

    if (!navigationCommand.containsKey('steps')) {
      throw Exception(_invalidResponseError);
    }

    return navigationCommand;
  }

  // App Structure Definition

  /// Complete app navigation structure for AI context
  ///
  /// This structure describes all available screens, tabs, and actions
  /// that the AI can use to generate navigation commands
  static const Map<String, dynamic> _appStructure = {
    "tabs": [
      {
        "index": 0,
        "name": "Home",
        "description":
            "Dashboard with statistics and user info",
      },
      {
        "index": 1,
        "name": "Text Enhancement",
        "description":
            "Text enhancement tools and features",
      },
      {
        "index": 2,
        "name": "AI Chat",
        "description": "AI assistant chat interface",
      },
      {
        "index": 3,
        "name": "My Profile",
        "description": "User profile information",
        "sub_tabs": [
          {
            "index": 0,
            "name": "Overview",
            "fields": [
              {"name": "Name", "highlightable": false},
              {"name": "Email", "highlightable": true},
              {"name": "Phone", "highlightable": true},
              {"name": "Role", "highlightable": false},
              {
                "name": "Department",
                "highlightable": false,
              },
              {
                "name": "Employee Code",
                "highlightable": false,
              },
              {
                "name": "Date of Birth",
                "highlightable": false,
              },
              {"name": "Gender", "highlightable": false},
              {
                "name": "Nationality",
                "highlightable": false,
              },
            ],
          },
          {
            "index": 1,
            "name": "Projects",
            "description": "List of projects I worked on",
          },
          {
            "index": 2,
            "name": "Time Tracker",
            "description": "My time tracking data",
          },
          {
            "index": 3,
            "name": "Reports",
            "description": "My reports and analytics",
          },
        ],
      },
      {
        "index": 4,
        "name": "Directory",
        "description": "Browse projects and staff",
        "sub_tabs": [
          {
            "index": 0,
            "name": "Projects",
            "searchable": true,
            "search_action": "search_project",
            "search_fields": [
              "title",
              "code",
              "description",
              "location",
              "status",
            ],
            "navigate_action":
                "navigate_to_project_details",
            "detail_page": {
              "name": "Project Details",
              "tabs": [
                {
                  "index": 0,
                  "name": "Overview",
                  "fields": [
                    "Name",
                    "Code",
                    "Location",
                    "Description",
                    "Start Date",
                    "End Date",
                    "Status",
                    "Total Working Hours",
                    "Number of Milestones",
                    "Budget",
                  ],
                },
                {
                  "index": 1,
                  "name": "Time Tracker",
                  "description":
                      "Project time tracking records",
                },
                {
                  "index": 2,
                  "name": "Milestones",
                  "description":
                      "Project milestones and progress",
                },
                {
                  "index": 3,
                  "name": "Members",
                  "description":
                      "Team members working on project",
                },
                {
                  "index": 4,
                  "name": "Tasks",
                  "description": "Project tasks",
                },
                {
                  "index": 5,
                  "name": "Facts",
                  "description": "Project facts",
                },
              ],
            },
          },
          {
            "index": 1,
            "name": "Staff",
            "searchable": true,
            "search_action": "search_employee",
            "search_fields": [
              "name",
              "email",
              "designation",
              "department",
            ],
            "navigate_action": "navigate_to_profile",
            "detail_page": {
              "name": "Employee Profile",
              "sub_tabs": [
                {
                  "index": 0,
                  "name": "Overview",
                  "fields": [
                    {
                      "name": "Name",
                      "highlightable": false,
                    },
                    {
                      "name": "Email",
                      "highlightable": true,
                    },
                    {
                      "name": "Phone",
                      "highlightable": true,
                    },
                    {
                      "name": "Role/Designation",
                      "highlightable": false,
                    },
                    {
                      "name": "Department",
                      "highlightable": false,
                    },
                    {
                      "name": "Employee Code",
                      "highlightable": false,
                    },
                    {
                      "name": "Date of Birth",
                      "highlightable": false,
                    },
                    {
                      "name": "Gender",
                      "highlightable": false,
                    },
                    {
                      "name": "Nationality",
                      "highlightable": false,
                    },
                  ],
                },
                {
                  "index": 1,
                  "name": "Projects",
                  "description":
                      "Projects this employee worked on",
                },
                {
                  "index": 2,
                  "name": "Time Tracker",
                  "description":
                      "Employee's time tracking records",
                },
                {
                  "index": 3,
                  "name": "Reports",
                  "description":
                      "Employee's reports and analytics",
                },
              ],
            },
          },
        ],
      },
    ],
    "general_actions": ["Back"],
  };
}
