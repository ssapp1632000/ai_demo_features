import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/graphql_service.dart';
import '../themes.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => DashboardHeaderState();
}

// Made public so it can be accessed via GlobalKey from parent
class DashboardHeaderState extends State<DashboardHeader> {
  String userName = 'Loading...';
  String? profileImageUrl;
  bool isLoading = true;
  DateTime currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _startTimeUpdater();
  }

  // Fetch user data from GraphQL API
  Future<void> _fetchUserData() async {
    try {
      final userData = await GraphQLService.getMe();

      // Debug: Print received data
      print('Dashboard - User Data: $userData');
      print('Dashboard - Full Name: ${userData['fullName']}');
      print('Dashboard - Profile Image URL: ${userData['professionalImageUrl']}');

      if (mounted) {
        setState(() {
          // Use correct field names from API: fullName and professionalImageUrl
          userName = userData['fullName'] ?? 'User';
          profileImageUrl = userData['professionalImageUrl'];
          isLoading = false;
        });

        // Debug: Print what was set
        print('Dashboard - Set userName: $userName');
        print('Dashboard - Set profileImageUrl: $profileImageUrl');
      }
    } catch (e) {
      // If API call fails, show error in console but use a generic fallback
      print('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          userName = 'User'; // Generic fallback
          isLoading = false;
        });
      }
    }
  }

  // Public method to refresh data (can be called from parent)
  Future<void> refresh() async {
    setState(() {
      isLoading = true;
      userName = 'Loading...';
    });
    await _fetchUserData();
  }

  // Update time every minute
  void _startTimeUpdater() {
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() {
          currentTime = DateTime.now();
        });
        _startTimeUpdater();
      }
    });
  }

  // Get day letters (e.g., "M O N" for Monday)
  List<String> _getDayLetters() {
    String day = DateFormat('EEE').format(currentTime).toUpperCase();
    return day.split('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Welcome Text + Notification Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Motivated captions here',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Menu and Notification Icons
              Row(
                children: [
                  // Menu Icon
                  GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2) ?? Colors.grey,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.menu,
                        color: theme.textTheme.bodyMedium?.color,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Notification Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2) ?? Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: theme.textTheme.bodyMedium?.color,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bottom Row: Info Card with Day Letters + Profile Image
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Day Letters (Vertical)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _getDayLetters().map((letter) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                          height: 1.2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 16),
                // Date, Time, Weather Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        DateFormat('EEE, MMM d, yyyy').format(currentTime),
                        theme,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.access_time,
                        DateFormat('h:mm a').format(currentTime),
                        theme,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.wb_sunny_outlined,
                        'Weather Condition, Location',
                        theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Profile Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                    backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    onBackgroundImageError: profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? (exception, stackTrace) {
                            print('Dashboard - Error loading image: $exception');
                            print('Dashboard - Image URL was: $profileImageUrl');
                          }
                        : null,
                    child: profileImageUrl == null || profileImageUrl!.isEmpty
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
