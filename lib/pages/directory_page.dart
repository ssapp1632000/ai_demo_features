import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'profile_page.dart';
import 'project_details_page.dart';
import '../services/graphql_service.dart';
import '../models/project.dart';

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({super.key});

  @override
  State<DirectoryPage> createState() =>
      _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Public getter for tab controller (for external navigation)
  TabController get tabController => _tabController;

  // Public getters for loading states (for external navigation)
  bool get isLoadingProjects => _isLoadingProjects;
  bool get isLoadingEmployees => _isLoadingEmployees;

  // Public methods for external search control
  void searchEmployee(String query) {
    _staffSearchController.text = query;
    _filterEmployees(query);
  }

  void searchProject(String query) {
    _projectSearchController.text = query;
    _filterProjects(query);
  }

  Employee? getFirstFilteredEmployee() {
    return _filteredEmployees.isNotEmpty
        ? _filteredEmployees.first
        : null;
  }

  Project? getFirstFilteredProject() {
    return _filteredProjects.isNotEmpty
        ? _filteredProjects.first
        : null;
  }

  List<Project> _projects = [];
  bool _isLoadingProjects = false;
  String? _projectsError;

  List<Employee> _employees = [];
  bool _isLoadingEmployees = false;
  String? _employeesError;

  // Search controllers and filtered lists
  final TextEditingController _projectSearchController =
      TextEditingController();
  final TextEditingController _staffSearchController =
      TextEditingController();
  List<Project> _filteredProjects = [];
  List<Employee> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAndLoadProjects();
  }

  Future<void> _initializeAndLoadProjects() async {
    // Set the demo token automatically
    const demoToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjIsImVtYWlsIjoibXVlaW4uZmFsbGFoYUBzaWx2ZXJzdG9uZWFyY2hpdGVjdHMuY29tIiwiaWF0IjoxNzYzNDQyNDQzLCJleHAiOjE3NjQwNDcyNDN9.GxZb_Tn7KV18wqqbT07IO4q4ta0wgZ6cZSuBGV3-VqY';
    GraphQLService.setToken(demoToken);

    // Load projects and employees
    await Future.wait([_loadProjects(), _loadEmployees()]);
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoadingProjects = true;
      _projectsError = null;
    });

    try {
      // Try to fetch employee worked projects first
      final projectsData =
          await GraphQLService.getEmployeeWorkedProjects();

      setState(() {
        _projects = projectsData
            .map((json) => Project.fromJson(json))
            .toList();
        _filteredProjects = _projects;
        _isLoadingProjects = false;
      });
    } catch (e) {
      // If that fails, try to get all projects
      try {
        final response =
            await GraphQLService.getAllProjects(limit: 50);
        final edges = response['edges'] as List;

        setState(() {
          _projects = edges
              .map((edge) => Project.fromJson(edge['node']))
              .toList();
          _filteredProjects = _projects;
          _isLoadingProjects = false;
        });
      } catch (e2) {
        setState(() {
          _projectsError = e2.toString().replaceAll(
            'Exception: ',
            '',
          );
          _isLoadingProjects = false;
        });
      }
    }
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoadingEmployees = true;
      _employeesError = null;
    });

    try {
      final response = await GraphQLService.getAllEmployees(
        limit: 100,
      );
      final edges = response['edges'] as List;

      setState(() {
        _employees = edges
            .map((edge) => Employee.fromJson(edge['node']))
            .toList();
        _filteredEmployees = _employees;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _employeesError = e.toString().replaceAll(
          'Exception: ',
          '',
        );
        _isLoadingEmployees = false;
      });
    }
  }

  void _filterProjects(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProjects = _projects;
      } else {
        _filteredProjects = _projects.where((project) {
          final titleMatch = project.title
              .toLowerCase()
              .contains(query.toLowerCase());
          final codeMatch =
              project.projectCode?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
          final descriptionMatch =
              project.description?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
          final locationMatch =
              project.location?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
          final statusMatch =
              project.status?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;

          return titleMatch ||
              codeMatch ||
              descriptionMatch ||
              locationMatch ||
              statusMatch;
        }).toList();
      }
    });
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees.where((employee) {
          final nameMatch =
              employee.fullName?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
          final emailMatch = employee.email
              .toLowerCase()
              .contains(query.toLowerCase());
          final designationMatch =
              employee.designation?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
          final departmentMatch = employee.departmentName
              .toLowerCase()
              .contains(query.toLowerCase());

          return nameMatch ||
              emailMatch ||
              designationMatch ||
              departmentMatch;
        }).toList();
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'active':
      case 'in progress':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'on hold':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _projectSearchController.dispose();
    _staffSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.deepOrangeAccent,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "All Projects"),
              Tab(text: "All Staff"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProjectsList(),
              _buildStaffList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsList() {
    if (_isLoadingProjects) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.deepOrangeAccent,
            ),
            SizedBox(height: 16),
            Text('Loading projects...'),
          ],
        ),
      );
    }

    if (_projectsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load projects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _projectsError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProjects,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search TextField
        Padding(
          padding: EdgeInsets.all(15),
          child: TextField(
            controller: _projectSearchController,
            decoration: InputDecoration(
              hintText: 'Search projects...',
              prefixIcon: Icon(
                Icons.search,
                color: Colors.deepOrangeAccent,
              ),
              suffixIcon:
                  _projectSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _projectSearchController.clear();
                        _filterProjects('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.deepOrangeAccent,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _filterProjects,
          ),
        ),
        // List
        Expanded(
          child: _filteredProjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _projectSearchController
                                .text
                                .isEmpty
                            ? 'No projects found'
                            : 'No matching projects',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProjects,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15,
                    ),
                    itemCount: _filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project =
                          _filteredProjects[index];
                      return _buildProjectCard(project);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStaffList() {
    if (_isLoadingEmployees) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.deepOrangeAccent,
            ),
            SizedBox(height: 16),
            Text('Loading employees...'),
          ],
        ),
      );
    }

    if (_employeesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load employees',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _employeesError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadEmployees,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search TextField
        Padding(
          padding: EdgeInsets.all(15),
          child: TextField(
            controller: _staffSearchController,
            decoration: InputDecoration(
              hintText: 'Search staff...',
              prefixIcon: Icon(
                Icons.search,
                color: Colors.deepOrangeAccent,
              ),
              suffixIcon:
                  _staffSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _staffSearchController.clear();
                        _filterEmployees('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.deepOrangeAccent,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _filterEmployees,
          ),
        ),
        // List
        Expanded(
          child: _filteredEmployees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _staffSearchController.text.isEmpty
                            ? 'No employees found'
                            : 'No matching staff',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEmployees,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15,
                    ),
                    itemCount: _filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee =
                          _filteredEmployees[index];
                      return _buildEmployeeCard(employee);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Project project) {
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(project.status);
    final isActive = project.isActive ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.withValues(alpha: 0.15),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isDarkMode ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode
            ? Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.1,
                  ),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsPage(
                projectId: project.id,
                projectName: project.title,
                project: project,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status Row
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color,
                          ),
                        ),
                        if (project.projectCode != null)
                          Text(
                            project.projectCode!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (project.status != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Text(
                        project.status!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                ],
              ),

              // Description
              if (project.description != null) ...[
                SizedBox(height: 8),
                Text(
                  project.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: 12),

              // Info Row
              Wrap(
                spacing: 15,
                runSpacing: 8,
                children: [
                  if (project.startDate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 5),
                        Text(
                          _formatDate(project.startDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  if (project.location != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 5),
                        Text(
                          project.location!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  if (project.totalDurationWorked != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 5),
                        Text(
                          project.totalDurationWorked!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    )
                  else if (project.totalHours != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 5),
                        Text(
                          '${project.totalHours} hrs',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  if (isActive)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: Colors.green,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark;
    final name = employee.fullName ?? 'Unknown';
    final designation = employee.designation ?? 'N/A';
    final department = employee.departmentName;

    // Get initials for avatar
    String initials = 'U';
    if (employee.fullName != null &&
        employee.fullName!.isNotEmpty) {
      final nameParts = employee.fullName!.split(' ');
      if (nameParts.length >= 2) {
        initials = nameParts[0][0] + nameParts[1][0];
      } else {
        initials = nameParts[0][0];
      }
    }

    // Construct full image URL
    String? imageUrl;
    if (employee.professionalImageUrl != null) {
      // If the URL is relative, prepend the base URL with /cms-uploads/ prefix
      if (!employee.professionalImageUrl!.startsWith(
        'http',
      )) {
        imageUrl =
            'http://172.105.77.204:9000/cms-uploads/${employee.professionalImageUrl}';
      } else {
        imageUrl = employee.professionalImageUrl;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.withValues(alpha: 0.15),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isDarkMode ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode
            ? Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.1,
                  ),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                userId: employee.id,
                userName: name,
                userRole: designation,
                userDepartment: department,
                userEmail: employee.email,
                userImageUrl: imageUrl,
                employee: employee,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              // Avatar with professional image or initials
              imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
                                // Show initials if image fails to load
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors
                                      .deepOrangeAccent,
                                  child: Center(
                                    child: Text(
                                      initials
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress
                                              .expectedTotalBytes !=
                                          null
                                      ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress
                                                .expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<
                                        Color
                                      >(
                                        Colors
                                            .deepOrangeAccent,
                                      ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.deepOrangeAccent,
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).textTheme.titleMedium?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      designation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.deepOrangeAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      department,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
