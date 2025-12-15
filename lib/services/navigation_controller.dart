import 'package:flutter/material.dart';
import '../models/project.dart';
import '../pages/profile_page.dart';
import '../pages/project_details_page.dart';

/// Navigation Controller
/// Executes navigation commands from backend responses
class NavigationController {
  final BuildContext context;
  final Function(int) onTabChange;
  final Function(int)? onSubTabChange;
  final GlobalKey? directoryPageKey;

  // Store references for navigation
  Employee? _foundEmployee;
  Project? _foundProject;
  bool _isNavigating = false;
  bool _loadingOverlayClosed = false;

  // Store reference to last navigated detail page for sub-tab switching
  GlobalKey? _lastNavigatedPageKey;

  NavigationController({
    required this.context,
    required this.onTabChange,
    this.onSubTabChange,
    this.directoryPageKey,
  });

  /// Execute a navigation command from backend response
  Future<void> executeCommand(Map<String, dynamic> response) async {
    print('🔵 [NAV] Starting command execution');
    print('🔵 [NAV] Response: $response');

    if (_isNavigating) {
      print('⚠️ [NAV] Navigation already in progress');
      if (context.mounted) {
        _showMessage('Navigation already in progress...', isError: true);
      }
      return;
    }

    _isNavigating = true;
    _foundEmployee = null;
    _foundProject = null;
    _loadingOverlayClosed = false;

    try {
      final steps = response['steps'] as List;
      final successMessage = response['success_message'];
      final errorFallback = response['error_fallback'];

      print('🔵 [NAV] Total steps: ${steps.length}');
      print('🔵 [NAV] Success message: $successMessage');
      print('🔵 [NAV] Error fallback: $errorFallback');

      // Show loading overlay
      if (context.mounted) {
        _showLoadingOverlay();
      }

      // Execute each step sequentially
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        final action = step['action'];

        print('🔵 [NAV] Step ${i + 1}/${steps.length}: $action');
        print('🔵 [NAV] Step data: $step');

        try {
          await _executeStep(action, step);
          print('🟢 [NAV] Step ${i + 1} completed: $action');

          // No fixed delays - each step waits for completion naturally
        } catch (e) {
          print('🔴 [NAV ERROR] Step ${i + 1} failed: $action');
          print('🔴 [NAV ERROR] Error details: $e');
          print('🔴 [NAV ERROR] Stack trace: ${StackTrace.current}');

          // Hide loading and show error
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showMessage(errorFallback ?? e.toString(), isError: true);
          }
          _isNavigating = false;
          return;
        }
      }

      // Hide loading overlay (only if it wasn't already closed)
      if (context.mounted && !_loadingOverlayClosed) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        // Show success message
        _showMessage(successMessage ?? 'Navigation completed', isError: false);
      }

      _isNavigating = false;
      _loadingOverlayClosed = false;
    } catch (e) {
      // Hide loading if it's still showing
      if (context.mounted && !_loadingOverlayClosed) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _showMessage('Navigation failed: $e', isError: true);
      }
      _isNavigating = false;
      _loadingOverlayClosed = false;
    }
  }

  /// Execute a single navigation step
  Future<void> _executeStep(String action, Map<String, dynamic> step) async {
    switch (action) {
      case 'switch_tab':
        await _switchTab(step['index']);
        break;

      case 'switch_sub_tab':
        await _switchSubTab(step['index']);
        break;

      case 'search_employee':
        await _searchEmployee(step['query']);
        break;

      case 'search_project':
        await _searchProject(step['query']);
        break;

      case 'navigate_to_profile':
        await _navigateToProfile(step);
        break;

      case 'navigate_to_project_details':
        await _navigateToProjectDetails(step);
        break;

      default:
        throw Exception('Unknown action: $action');
    }
  }

  /// Switch bottom navigation tab
  Future<void> _switchTab(int index) async {
    onTabChange(index);
    // Wait for frame to render
    await Future.delayed(Duration(milliseconds: 50));
  }

  /// Switch sub-tab (e.g., Directory: Projects/Staff, Profile tabs, or navigated detail pages)
  Future<void> _switchSubTab(int index) async {
    print('🔵 [NAV] _switchSubTab called with index: $index');
    print('🔵 [NAV] _lastNavigatedPageKey: $_lastNavigatedPageKey');

    // Check if we have a recently navigated detail page (Profile or Project Details)
    if (_lastNavigatedPageKey != null) {
      print('🔵 [NAV] Attempting to switch tab on detail page');
      final pageState = _lastNavigatedPageKey!.currentState;
      print('🔵 [NAV] Page state: $pageState');

      if (pageState != null) {
        try {
          print('🔵 [NAV] Accessing tabController on detail page');
          final tabController = (pageState as dynamic).tabController;
          print('🔵 [NAV] TabController found: $tabController');
          print('🔵 [NAV] Animating to index: $index');

          tabController.animateTo(index);
          print('🟢 [NAV] Tab animation started successfully');

          // Wait for tab animation to complete
          await Future.delayed(Duration(milliseconds: 350));
          print('🟢 [NAV] Sub-tab switch completed on detail page');
          return;
        } catch (e) {
          print('🔴 [NAV ERROR] Failed to switch tab on detail page: $e');
          print('🔴 [NAV ERROR] pageState type: ${pageState.runtimeType}');
          throw Exception('Failed to switch sub-tab on detail page: $e');
        }
      } else {
        print('⚠️ [NAV] pageState is null, falling back to main app sub-tab switching');
      }
    } else {
      print('🔵 [NAV] No detail page, using main app sub-tab switching');
    }

    // Otherwise, use the main app's sub-tab switching (Directory/My Profile)
    if (onSubTabChange != null) {
      print('🔵 [NAV] Calling onSubTabChange with index: $index');
      onSubTabChange!(index);
      print('🟢 [NAV] onSubTabChange called successfully');

      // Wait for tab animation to complete
      await Future.delayed(Duration(milliseconds: 350));

      // Additional wait for data to load if needed
      // This allows the page to finish loading its data
      await Future.delayed(Duration(milliseconds: 500));
      print('🟢 [NAV] Sub-tab switch completed on main app');
    } else {
      print('⚠️ [NAV] onSubTabChange is null, cannot switch sub-tab');
      throw Exception('Cannot switch sub-tab: onSubTabChange callback is null');
    }
  }

  /// Search for employee by name using frontend search
  Future<void> _searchEmployee(String query) async {
    try {
      // Get DirectoryPage state and perform frontend search
      final directoryState = directoryPageKey?.currentState;
      if (directoryState == null) {
        throw Exception('Directory page not available');
      }

      // Wait for employees to load (check loading state)
      int waitAttempts = 0;
      const maxWaitAttempts = 20; // Max 10 seconds (500ms * 20)
      while (waitAttempts < maxWaitAttempts) {
        final isLoading = (directoryState as dynamic).isLoadingEmployees;
        if (!isLoading) {
          break; // Data loaded
        }
        await Future.delayed(Duration(milliseconds: 500));
        waitAttempts++;
      }

      // Perform frontend search - this will update the search field and filter the list
      (directoryState as dynamic).searchEmployee(query);

      // Wait a bit for the UI to update
      await Future.delayed(Duration(milliseconds: 300));

      // Get the first filtered result
      final firstEmployee = (directoryState as dynamic).getFirstFilteredEmployee();

      if (firstEmployee == null) {
        throw Exception('Employee "$query" not found');
      }

      _foundEmployee = firstEmployee;
    } catch (e) {
      throw Exception('Could not find employee: $query');
    }
  }

  /// Search for project by name using frontend search
  Future<void> _searchProject(String query) async {
    try {
      // Get DirectoryPage state and perform frontend search
      final directoryState = directoryPageKey?.currentState;
      if (directoryState == null) {
        throw Exception('Directory page not available');
      }

      // Wait for projects to load (check loading state)
      int waitAttempts = 0;
      const maxWaitAttempts = 20; // Max 10 seconds (500ms * 20)
      while (waitAttempts < maxWaitAttempts) {
        final isLoading = (directoryState as dynamic).isLoadingProjects;
        if (!isLoading) {
          break; // Data loaded
        }
        await Future.delayed(Duration(milliseconds: 500));
        waitAttempts++;
      }

      // Perform frontend search - this will update the search field and filter the list
      (directoryState as dynamic).searchProject(query);

      // Wait a bit for the UI to update
      await Future.delayed(Duration(milliseconds: 300));

      // Get the first filtered result
      final firstProject = (directoryState as dynamic).getFirstFilteredProject();

      if (firstProject == null) {
        throw Exception('Project "$query" not found');
      }

      _foundProject = firstProject;
    } catch (e) {
      throw Exception('Could not find project: $query');
    }
  }

  /// Navigate to employee profile page (simulating card tap)
  Future<void> _navigateToProfile(Map<String, dynamic> step) async {
    if (_foundEmployee == null) {
      throw Exception('No employee found to navigate to');
    }

    if (!context.mounted) return;

    final highlightField = step['highlight_field'] as String?;

    // Close the loading overlay first
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      _loadingOverlayClosed = true; // Mark as closed
    }

    // Create a GlobalKey for the profile page to allow tab switching
    final profilePageKey = GlobalKey();
    _lastNavigatedPageKey = profilePageKey;

    // Navigate to profile page exactly like the card tap does
    // Always opens at tab 0 (Overview) - use switch_sub_tab to change tabs after
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          key: profilePageKey,
          userId: _foundEmployee!.id,
          userName: _foundEmployee!.fullName,
          userRole: _foundEmployee!.designation,
          userDepartment: _foundEmployee!.departmentName,
          userEmail: _foundEmployee!.email,
          userImageUrl: _foundEmployee!.professionalImageUrl,
          employee: _foundEmployee,
          highlightField: highlightField,
          initialTabIndex: 0, // Always start at Overview tab
        ),
      ),
    );

    // Clear the reference when user returns from profile page
    _lastNavigatedPageKey = null;

    // Show success message after user returns
    if (context.mounted) {
      _showMessage('Navigated to profile successfully', isError: false);
    }
  }

  /// Navigate to project details page (simulating card tap)
  Future<void> _navigateToProjectDetails(Map<String, dynamic> step) async {
    if (_foundProject == null) {
      throw Exception('No project found to navigate to');
    }

    if (!context.mounted) return;

    // Close the loading overlay first
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      _loadingOverlayClosed = true; // Mark as closed
    }

    // Create a GlobalKey for the project page to allow tab switching
    final projectPageKey = GlobalKey();
    _lastNavigatedPageKey = projectPageKey;

    // Navigate to project details page exactly like the card tap does
    // Always opens at tab 0 (Overview) - use switch_sub_tab to change tabs after
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailsPage(
          key: projectPageKey,
          projectId: _foundProject!.id,
          projectName: _foundProject!.title,
          project: _foundProject!,
          initialTabIndex: 0, // Always start at Overview tab
        ),
      ),
    );

    // Clear the reference when user returns from project page
    _lastNavigatedPageKey = null;

    // Show success message after user returns
    if (context.mounted) {
      _showMessage('Navigated to project successfully', isError: false);
    }
  }

  /// Show loading overlay
  void _showLoadingOverlay() {
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
                    'Navigating...',
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
  }

  /// Show success or error message
  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
