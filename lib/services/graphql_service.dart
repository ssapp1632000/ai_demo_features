import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// GraphQL API Service for HR Management System
/// Handles authentication and all GraphQL queries/mutations
class GraphQLService {
  static const String _baseUrl =
      'https://concrete-glowworm-winning.ngrok-free.app/graphql';

  // Token storage (in production, use secure storage like flutter_secure_storage)
  static String? _accessToken;
  static String? _refreshToken;

  /// Get current access token
  static String? get accessToken => _accessToken;

  /// Check if user is authenticated
  static bool get isAuthenticated => _accessToken != null;

  /// Set access token directly (for development/testing)
  static void setToken(String token) {
    _accessToken = token;
  }

  /// Login with email and password
  /// Returns true if login successful
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    const mutation = '''
      mutation Login(\$email: String!, \$password: String!) {
        Auth_login(input: { email: \$email, password: \$password }) {
          accessToken
          refreshToken
          requiresTwoFactor
          sessionId
          profileCompleteness
          employee {
            id
            fullName
            email
            employeeCode
            department {
              id
              name
            }
            designation
          }
        }
      }
    ''';
    final response = await _executeQuery(
      mutation,
      variables: {'email': email, 'password': password},
      requiresAuth: false,
    );

    if (response['errors'] != null) {
      throw Exception(response['errors'][0]['message']);
    }

    final authData = response['data']['Auth_login'];

    // Check if 2FA is required
    if (authData['requiresTwoFactor'] == true) {
      // In production, you'd handle face verification here
      throw Exception(
        '2FA required. Face verification not implemented in this demo.',
      );
    }

    // Store tokens
    _accessToken = authData['accessToken'];
    _refreshToken = authData['refreshToken'];

    return authData;
  }

  /// Logout and clear tokens
  static Future<void> logout() async {
    try {
      const mutation = '''
        mutation Logout {
          Auth_logout
        }
      ''';

      await _executeQuery(mutation);
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _accessToken = null;
      _refreshToken = null;
    }
  }

  /// Get current authenticated user profile
  static Future<Map<String, dynamic>> getMe() async {
    const query = '''
      query GetMe {
        Auth_me {
          id
          fullName
          email
          employeeCode
          phone
          dateOfBirth
          gender
          nationality
          professionalImageUrl
          department {
            id
            name
            code
          }
          designation
        }
      }
    ''';

    final response = await _executeQuery(query);

    if (response['errors'] != null) {
      throw Exception(response['errors'][0]['message']);
    }

    return response['data']['Auth_me'];
  }

  /// Get all projects with optional filtering
  static Future<Map<String, dynamic>> getAllProjects({
    int limit = 20,
    String? cursor,
  }) async {
    const query = '''
      query GetAllProjects(\$pagination: PaginationInput) {
        Project_getAll(pagination: \$pagination) {
          edges {
            cursor
            node {
              id
              title
              projectCode
              description
              startDate
              status
              imageUrl
              totalHours
              createdAt
              updatedAt
              address {
                id
                city
                district
              }
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      }
    ''';

    final response = await _executeQuery(
      query,
      variables: {
        'pagination': {
          'limit': limit,
          if (cursor != null) 'after': cursor,
        },
      },
    );

    if (response['errors'] != null) {
      throw Exception(response['errors'][0]['message']);
    }

    return response['data']['Project_getAll'];
  }

  /// Get projects the employee worked on
  static Future<List<dynamic>> getEmployeeWorkedProjects({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    const query = '''
      query GetEmployeeWorkedProjects(
        \$userId: Int
        \$startDate: DateTime
        \$endDate: DateTime
      ) {
        Project_employeeWorkedProjects(
          userId: \$userId
          startDate: \$startDate
          endDate: \$endDate
        ) {
          id
          title
          projectCode
          description
          startDate
          status
          totalDurationWorked
          isActive
          imageUrl
          totalHours
          address {
            id
            city
            district
          }
        }
      }
    ''';

    final response = await _executeQuery(
      query,
      variables: {
        if (userId != null) 'userId': userId,
        if (startDate != null)
          'startDate': startDate.toIso8601String(),
        if (endDate != null)
          'endDate': endDate.toIso8601String(),
      },
    );

    if (response['errors'] != null) {
      throw Exception(response['errors'][0]['message']);
    }

    return response['data']['Project_employeeWorkedProjects'];
  }

  /// Get milestones for a specific project
  static Future<List<dynamic>> getProjectMilestones(
    int projectId,
  ) async {
    const query = '''
      query GetProjectMilestones(\$projectId: Int!) {
        Milestone_getByProjectId(projectId: \$projectId) {
          id
          title
          description
          phase
          startDate
          endDate
          status
          deliverables
          sequence
          completionPercentage
          createdAt
          updatedAt
        }
      }
    ''';

    final response = await _executeQuery(
      query,
      variables: {'projectId': projectId},
    );

    if (response['errors'] != null) {
      throw Exception(response['errors'][0]['message']);
    }

    return response['data']['Milestone_getByProjectId'];
  }

  /// Get daily reports for employee/project
  static Future<List<dynamic>> getEmployeeDailyReports({
    int? employeeId,
    int? projectId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    const query = '''
      query GetEmployeeDailyReports(
        \$employeeId: Int
        \$projectId: Int
        \$startDate: DateTime
        \$endDate: DateTime
      ) {
        DailyReport_employeeDailyReports(
          employeeId: \$employeeId
          projectId: \$projectId
          startDate: \$startDate
          endDate: \$endDate
        ) {
          id
          title
          description
          date
          createdAt
          employee {
            id
            fullName
          }
          project {
            id
            title
          }
        }
      }
    ''';

    final response = await _executeQuery(
      query,
      variables: {
        if (employeeId != null) 'employeeId': employeeId,
        if (projectId != null) 'projectId': projectId,
        if (startDate != null)
          'startDate': startDate.toIso8601String(),
        if (endDate != null)
          'endDate': endDate.toIso8601String(),
      },
    );

    if (response['errors'] != null) {
      throw Exception(response['errors'][0]['message']);
    }

    return response['data']['DailyReport_employeeDailyReports'];
  }

  /// Get all employees with optional filtering
  static Future<Map<String, dynamic>> getAllEmployees({
    int limit = 50,
    String? cursor,
  }) async {
    const query = '''
      query GetAllEmployees(\$pagination: PaginationInput) {
        Employee_getAll(pagination: \$pagination) {
          edges {
            cursor
            node {
              id
              employeeCode
              fullName
              email
              phone
              department {
                id
                name
              }
              roles {
                role {
                  id
                  name
                }
              }
              designation
              dateOfBirth
              gender
              nationality
              professionalImageUrl
              isActive
              dateJoined
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      }
    ''';

    final response = await _executeQuery(
      query,
      variables: {
        'pagination': {
          'limit': limit,
          if (cursor != null) 'after': cursor,
        },
      },
    );

    if (response['errors'] != null) {
      throw Exception(response['errors'][0]['message']);
    }

    return response['data']['Employee_getAll'];
  }

  /// Execute a GraphQL query/mutation
  static Future<Map<String, dynamic>> _executeQuery(
    String query, {
    Map<String, dynamic>? variables,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add authorization header if authenticated
      if (requiresAuth && _accessToken != null) {
        headers['Authorization'] = 'Bearer $_accessToken';
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode({
          'query': query,
          if (variables != null) 'variables': variables,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'GraphQL request failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('GraphQL Error: $e');
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  static Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      const mutation = '''
        mutation RefreshToken(\$refreshToken: String!) {
          Auth_refreshAccessToken(refreshToken: \$refreshToken) {
            accessToken
            refreshToken
          }
        }
      ''';

      final response = await _executeQuery(
        mutation,
        variables: {'refreshToken': _refreshToken},
        requiresAuth: false,
      );

      if (response['errors'] != null) {
        return false;
      }

      final authData =
          response['data']['Auth_refreshAccessToken'];
      _accessToken = authData['accessToken'];
      _refreshToken = authData['refreshToken'];

      return true;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }
}
