import 'package:flutter/material.dart';
import '../widgets/background_wrapper.dart';
import '../models/project.dart';
import '../services/graphql_service.dart';

class ProfilePage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? userRole;
  final String? userDepartment;
  final String? userEmail;
  final String? userImageUrl;
  final Employee? employee;
  final String? highlightField; // Field to highlight (e.g., 'phone')
  final int? initialTabIndex; // Initial tab to show

  const ProfilePage({
    super.key,
    this.userId,
    this.userName,
    this.userRole,
    this.userDepartment,
    this.userEmail,
    this.userImageUrl,
    this.employee,
    this.highlightField,
    this.initialTabIndex,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Public getter for tab controller (for external navigation)
  TabController get tabController => _tabController;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  // For highlighting fields
  final GlobalKey _phoneFieldKey = GlobalKey();
  bool _highlightPhone = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );

    // Only load current user data if no userId is provided (viewing own profile)
    if (widget.userId == null) {
      _loadCurrentUser();
    } else {
      // Viewing another user's profile, use provided data
      setState(() {
        _isLoading = false;
      });

      // Scroll to and highlight field after build
      if (widget.highlightField == 'phone') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAndHighlightPhone();
        });
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final data = await GraphQLService.getMe();

      // Debug: Print received data
      print('Profile - User Data: $data');
      print('Profile - Full Name: ${data['fullName']}');
      print('Profile - Profile Image URL: ${data['professionalImageUrl']}');

      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });

        // Scroll to and highlight field after data loads
        if (widget.highlightField == 'phone') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToAndHighlightPhone();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Scroll to phone field and highlight it
  void _scrollToAndHighlightPhone() {
    final context = _phoneFieldKey.currentContext;
    if (context != null) {
      // Scroll to the field
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3, // Position near top of screen
      );

      // Highlight the field
      setState(() {
        _highlightPhone = true;
      });

      // Remove highlight after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightPhone = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're showing another user's profile or current user
    final bool isOtherUser = widget.userId != null;

    // If loading current user data, show loading indicator
    if (!isOtherUser && _isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.deepOrangeAccent,
          ),
        ),
      );
    }

    // If error loading current user data, show error message
    if (!isOtherUser && _error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Failed to load profile data'),
              SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.grey)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadCurrentUser();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Get display values from API data or widget params
    final String displayName = isOtherUser
        ? (widget.userName ?? 'John Doe')
        : (_userData?['fullName'] ?? 'John Doe');
    final String displayRole = isOtherUser
        ? (widget.userRole ?? 'Software Engineer')
        : (_userData?['designation'] ?? 'Software Engineer');

    final profileContent = BackgroundWrapper(
      child: Column(
        children: [
          // Cover Image Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: isOtherUser
                  ? 20
                  : MediaQuery.of(context).padding.top,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrangeAccent,
                  Colors.orangeAccent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Avatar with professional image or initials
                // Get image URL from API data or widget params
                (isOtherUser ? widget.userImageUrl : _userData?['professionalImageUrl']) != null
                    ? CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.network(
                            isOtherUser ? widget.userImageUrl! : _userData?['professionalImageUrl'],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              print('Profile - Loading image: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Show initials if image fails to load
                              print('Profile - Error loading image: $error');
                              print('Profile - Image URL was: ${isOtherUser ? widget.userImageUrl : _userData?['professionalImageUrl']}');
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.white,
                                child: Center(
                                  child: Text(
                                    displayName
                                        .split(' ')
                                        .map((e) => e[0])
                                        .join(''),
                                    style: TextStyle(
                                      color: Colors.deepOrangeAccent,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: Text(
                          displayName
                              .split(' ')
                              .map((e) => e[0])
                              .join(''),
                          style: TextStyle(
                            color: Colors.deepOrangeAccent,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                SizedBox(height: 10),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  displayRole,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // TabBar Section
          Container(
            color: Colors.deepOrangeAccent,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.tab,
              isScrollable: false,
              tabs: [
                Tab(text: "Personal Info"),
                Tab(text: "Tech Info"),
                Tab(text: "Appraisals"),
                Tab(text: "Reports"),
              ],
            ),
          ),
          // Tab Content Section
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfo(),
                _buildTechInfo(),
                _buildAppraisals(),
                _buildReports(),
              ],
            ),
          ),
        ],
      ),
    );

    // If accessed from directory (has userId), wrap in Scaffold with AppBar
    if (isOtherUser) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            displayName,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.deepOrangeAccent,
          elevation: 4,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: profileContent,
      );
    }

    // Otherwise, return just the content (for main navigation)
    return profileContent;
  }

  // Personal Information Section
  Widget _buildPersonalInfo() {
    final bool isOtherUser = widget.userId != null;

    // Get display values from API data or widget params
    final String displayName = isOtherUser
        ? (widget.userName ?? 'John Doe')
        : (_userData?['fullName'] ?? 'John Doe');
    final String displayEmail = isOtherUser
        ? (widget.userEmail ?? 'john.doe@company.com')
        : (_userData?['email'] ?? 'john.doe@company.com');
    final String displayRole = isOtherUser
        ? (widget.userRole ?? 'Software Engineer')
        : (_userData?['designation'] ?? 'Software Engineer');
    final String displayDepartment = isOtherUser
        ? (widget.userDepartment ?? 'Engineering Department')
        : (_userData?['department']?['name'] ?? 'Engineering Department');
    final String displayPhone = isOtherUser
        ? (widget.employee?.phone ?? 'N/A')
        : (_userData?['phone'] ?? 'N/A');

    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildInfoItem('Name', displayName),
          _buildInfoItem('Email', displayEmail),
          Container(
            key: _phoneFieldKey,
            padding: EdgeInsets.all(_highlightPhone ? 12 : 0),
            decoration: BoxDecoration(
              color: _highlightPhone ? Colors.yellow.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: _highlightPhone
                  ? Border.all(color: Colors.orange, width: 2)
                  : null,
            ),
            child: _buildInfoItem('Phone', displayPhone),
          ),
          _buildInfoItem('Role', displayRole),
          _buildInfoItem('Department', displayDepartment),
        ],
      ),
    );
  }

  // Tech Info Section
  Widget _buildTechInfo() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Technical Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildInfoItem('Programming Languages', 'Dart, JavaScript, Python, Java'),
          _buildInfoItem('Frameworks', 'Flutter, React, Node.js, Django'),
          _buildInfoItem('Databases', 'PostgreSQL, MongoDB, Firebase'),
          _buildInfoItem('Cloud Platforms', 'AWS, Google Cloud, Azure'),
          _buildInfoItem('Version Control', 'Git, GitHub, GitLab'),
          _buildInfoItem('DevOps', 'Docker, Kubernetes, CI/CD'),
          _buildInfoItem('Mobile Development', 'iOS & Android'),
          _buildInfoItem('API Development', 'REST, GraphQL'),
          _buildInfoItem('Testing', 'Unit Testing, Integration Testing'),
          _buildInfoItem('Certifications', 'AWS Certified Developer'),
        ],
      ),
    );
  }

  // Appraisals Section
  Widget _buildAppraisals() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Appraisals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildAppraisalItem(
            'Annual Review 2024',
            'January 2024',
            'Outstanding',
            Colors.green,
            'Exceeded expectations in all areas. Demonstrated exceptional technical leadership and mentored junior developers effectively.',
          ),
          SizedBox(height: 20),
          _buildAppraisalItem(
            'Mid-Year Review 2023',
            'July 2023',
            'Exceeds Expectations',
            Colors.blue,
            'Strong performance across projects. Consistently delivers high-quality code and meets all deadlines.',
          ),
          SizedBox(height: 20),
          _buildAppraisalItem(
            'Annual Review 2023',
            'January 2023',
            'Meets Expectations',
            Colors.orange,
            'Good overall performance. Shows steady improvement in technical skills and team collaboration.',
          ),
          SizedBox(height: 20),
          _buildAppraisalItem(
            'Mid-Year Review 2022',
            'July 2022',
            'Exceeds Expectations',
            Colors.blue,
            'Excellent work on mobile app development. Proactive in solving complex technical challenges.',
          ),
        ],
      ),
    );
  }

  // Reports Section
  Widget _buildReports() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Work Reports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildReportItem(
            'Q4 2024 Performance Report',
            'December 15, 2024',
            'Submitted',
            Colors.green,
          ),
          SizedBox(height: 15),
          _buildReportItem(
            'Project Milestone Report',
            'November 28, 2024',
            'Approved',
            Colors.green,
          ),
          SizedBox(height: 15),
          _buildReportItem(
            'Weekly Status Report #45',
            'November 8, 2024',
            'Approved',
            Colors.green,
          ),
          SizedBox(height: 15),
          _buildReportItem(
            'Technical Documentation',
            'October 22, 2024',
            'In Review',
            Colors.orange,
          ),
          SizedBox(height: 15),
          _buildReportItem(
            'Q3 2024 Summary Report',
            'September 30, 2024',
            'Approved',
            Colors.green,
          ),
          SizedBox(height: 15),
          _buildReportItem(
            'Code Review Report',
            'September 15, 2024',
            'Approved',
            Colors.green,
          ),
          SizedBox(height: 15),
          _buildReportItem(
            'Training Completion Report',
            'August 20, 2024',
            'Approved',
            Colors.green,
          ),
        ],
      ),
    );
  }

  // Helper widget for info items with bullet points
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8, right: 10),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepOrangeAccent,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrangeAccent,
                    ),
                  ),
                  TextSpan(
                    text: value,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for appraisal items
  Widget _buildAppraisalItem(
    String title,
    String date,
    String rating,
    Color ratingColor,
    String feedback,
  ) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardTheme.color,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).textTheme.titleLarge?.color,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ratingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rating,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ratingColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: 10),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for report items
  Widget _buildReportItem(
    String title,
    String date,
    String status,
    Color statusColor,
  ) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).textTheme.titleLarge?.color,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
