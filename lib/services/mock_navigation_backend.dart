/// Mock backend service that provides hardcoded navigation responses
/// This simulates what the real AI backend will return
class MockNavigationBackend {
  /// Get navigation command for a specific test case
  /// Test cases:
  /// 1 - Find Ammar's phone number
  /// 2 - Show my reports
  /// 3 - Show Binghatti project time tracker
  static Map<String, dynamic> getNavigationCommand(
    int testCase,
  ) {
    switch (testCase) {
      case 1:
        return _getTestCase1();
      case 2:
        return _getTestCase2();
      case 3:
        return _getTestCase3();
      default:
        return _getErrorResponse(
          'Invalid test case: $testCase',
        );
    }
  }

  /// Test Case 1: Find employee phone number
  /// Voice command: "Show me Ammar's phone number"
  ///
  /// IMPORTANT: Change the 'query' value below to search for a different employee
  /// Example: Change 'ammar' to 'belal' to search for Belal instead
  static Map<String, dynamic> _getTestCase1() {
    return {
      'test_case': 1,
      'intent': 'find_contact_info',
      'description': 'Find employee phone number',
      'steps': [
        {
          'action': 'switch_tab',
          'index': 4,
          'name': 'directory',
          
        },
        {
          'action': 'switch_sub_tab',
          'index': 1,
          'name': 'staff',
        },
        {
          'action': 'search_employee',
          'query':
              'za', // ← CHANGE THIS to search for different employee
        },
         {
          'action': 'switch_sub_tab',
          'index': 1,
          'name': 'staff',
        },
      ],
      'success_message': 'Found employee phone number',
      'error_fallback': 'Could not find employee',
      'confidence': 0.95,
    };
  }

  /// Test Case 2: Show my reports
  /// Voice command: "Show me my reports"
  static Map<String, dynamic> _getTestCase2() {
    return {
      'test_case': 2,
      'intent': 'navigate_to_section',
      'description': 'Show my reports',
      'steps': [
        {
          'action': 'switch_tab',
          'index': 3,
          'name': 'profile',
          'delay_ms': 300,
        },
        {
          'action': 'switch_sub_tab',
          'index': 3,
          'name': 'reports',
          'delay_ms': 300,
        },
      ],
      'success_message': 'Showing your reports',
      'error_fallback': 'Could not navigate to reports',
      'confidence': 0.98,
    };
  }

  /// Test Case 3: Show project time tracker
  /// Voice command: "Show me Binghatti project time tracker"
  ///
  /// IMPORTANT: Change the 'query' value below to search for a different project
  /// Example: Change 'binghatti' to 'downtown' to search for Downtown project
  static Map<String, dynamic> _getTestCase3() {
    return {
      'test_case': 3,
      'intent': 'navigate_to_project_section',
      'description': 'Show project time tracker',
      'steps': [
        {
          'action': 'switch_tab',
          'index': 4,
          'name': 'directory',
        },
        {
          'action': 'switch_sub_tab',
          'index': 0,
          'name': 'projects',
        },
        {
          'action': 'search_project',
          'query':
              'Rudu', // ← CHANGE THIS to search for different project
        },
        {
          'action': 'navigate_to_project_details',
          'initial_tab':
              1, // Time Tracker tab (0=Overview, 1=Time Tracker, etc.)
        },
      ],
      'success_message': 'Opened project time tracker',
      'error_fallback': 'Could not find project',
      'confidence': 0.92,
    };
  }

  /// Error response format
  static Map<String, dynamic> _getErrorResponse(
    String message,
  ) {
    return {
      'test_case': -1,
      'intent': 'error',
      'description': 'Error',
      'steps': [],
      'success_message': '',
      'error_fallback': message,
      'confidence': 0.0,
    };
  }

  /// Get list of all available test cases
  static List<Map<String, dynamic>> getAllTestCases() {
    return [
      {
        'id': 1,
        'name': 'Find Ammar\'s Phone',
        'description':
            'Navigate to employee profile and highlight phone number',
      },
      {
        'id': 2,
        'name': 'My Reports',
        'description': 'Navigate to your reports tab',
      },
      {
        'id': 3,
        'name': 'Binghatti Time Tracker',
        'description':
            'Navigate to Binghatti project time tracker',
      },
    ];
  }
}
