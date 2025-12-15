import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/background_wrapper.dart';
import '../models/project.dart';
import '../services/graphql_service.dart';

class ProjectDetailsPage extends StatefulWidget {
  final int? projectId;
  final String? projectName;
  final Project? project;
  final int? initialTabIndex; // Tab to open initially

  const ProjectDetailsPage({
    super.key,
    this.projectId,
    this.projectName,
    this.project,
    this.initialTabIndex,
  });

  @override
  State<ProjectDetailsPage> createState() =>
      _ProjectDetailsPageState();
}

class _ProjectDetailsPageState
    extends State<ProjectDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Milestone> _milestones = [];
  List<DailyReport> _dailyReports = [];
  bool _isLoadingMilestones = false;
  bool _isLoadingReports = false;

  final List<String> _tabTitles = [
    "Overview",
    "Time Tracker",
    "Reports",
    "Members",
    "Tasks",
    "Facts",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
    _tabController.addListener(() {
      setState(() {}); // Update UI when tab changes
    });

    // Load project data if we have a project ID
    if (widget.projectId != null ||
        widget.project != null) {
      _loadProjectData();
    }
  }

  Future<void> _loadProjectData() async {
    final projectId =
        widget.project?.id ?? widget.projectId;
    if (projectId == null) return;

    // Load milestones
    setState(() => _isLoadingMilestones = true);
    try {
      final milestonesData =
          await GraphQLService.getProjectMilestones(
            projectId,
          );
      setState(() {
        _milestones = milestonesData
            .map((json) => Milestone.fromJson(json))
            .toList();
        _isLoadingMilestones = false;
      });
    } catch (e) {
      setState(() => _isLoadingMilestones = false);
    }

    // Load daily reports
    setState(() => _isLoadingReports = true);
    try {
      final reportsData =
          await GraphQLService.getEmployeeDailyReports(
            projectId: projectId,
          );
      setState(() {
        _dailyReports = reportsData
            .map((json) => DailyReport.fromJson(json))
            .toList();
        _isLoadingReports = false;
      });
    } catch (e) {
      setState(() => _isLoadingReports = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're showing a specific project or default project
    final bool isSpecificProject = widget.projectId != null;
    final String displayName =
        widget.projectName ?? 'E-Commerce Mobile App';

    final projectContent = BackgroundWrapper(
      child: Row(
        children: [
          // Tab Content Section (Left Side)
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: _getCurrentTabContent(),
            ),
          ),
          // Vertical Navigation (Right Side)
          Container(
            width: 60,
            color: Colors.deepOrangeAccent,
            child: Column(
              children: List.generate(
                _tabTitles.length,
                (index) => _buildVerticalTabItem(
                  _tabTitles[index],
                  index,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // If accessed from directory (has projectId), wrap in Scaffold with AppBar
    if (isSpecificProject) {
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
        body: projectContent,
      );
    }

    // Otherwise, return just the content (for main navigation)
    return projectContent;
  }

  Widget _getCurrentTabContent() {
    Widget content;
    switch (_tabController.index) {
      case 0:
        content = _buildOverview();
        break;
      case 1:
        content = _buildTimeTracker();
        break;
      case 2:
        content = _buildReports();
        break;
      case 3:
        content = _buildMembers();
        break;
      case 4:
        content = _buildTasks();
        break;
      case 5:
        content = _buildFacts();
        break;
      default:
        content = _buildOverview();
    }
    return Container(
      key: ValueKey<int>(_tabController.index),
      child: content,
    );
  }

  Widget _buildVerticalTabItem(String title, int index) {
    bool isSelected = _tabController.index == index;

    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? Colors.white
                  : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white70,
              fontSize: 14,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Overview Section
  Widget _buildOverview() {
    final project = widget.project;
    final projectName =
        project?.title ??
        widget.projectName ??
        'E-Commerce Mobile App';
    final projectCode = project?.projectCode ?? 'N/A';
    final location = project?.location ?? 'N/A';
    final startDate = project?.startDate != null
        ? _formatDate(project!.startDate)
        : 'N/A';
    final status = project?.status ?? 'Active';
    final totalHours =
        project?.totalHours ??
        project?.totalDurationWorked ??
        'N/A';
    final description =
        project?.description ?? 'No description available';

    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Information',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
          SizedBox(height: 20),
          _buildInfoItem('Project Name: $projectName'),
          SizedBox(height: 15),
          _buildInfoItem('Project Code: $projectCode'),
          SizedBox(height: 15),
          _buildInfoItem('Location: $location'),
          SizedBox(height: 15),
          _buildInfoItem('Start Date: $startDate'),
          SizedBox(height: 15),
          _buildInfoItem('Status: $status'),
          SizedBox(height: 15),
          _buildInfoItem('Description: $description'),
          SizedBox(height: 40),

          // Key Metrics
          Text(
            'Key Metrics',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Hours',
                  totalHours.toString(),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildMetricCard(
                  'Milestones',
                  _milestones.length.toString(),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Reports',
                  _dailyReports.length.toString(),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildMetricCard(
                  'Tasks Done',
                  '15/20',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Time Tracker Section - Project Timeline with Milestones
  Widget _buildTimeTracker() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Timeline - Milestones',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
          SizedBox(height: 30),

          if (_isLoadingMilestones)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(
                  color: Colors.deepOrangeAccent,
                ),
              ),
            )
          else if (_milestones.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No milestones available for this project',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            Column(
              children: _milestones.asMap().entries.map((
                entry,
              ) {
                final index = entry.key;
                final milestone = entry.value;
                final isCompleted =
                    milestone.status?.toLowerCase() ==
                    'completed';
                final isLast =
                    index == _milestones.length - 1;

                return _buildTimelineItem(
                  milestone.title,
                  '${_formatDate(milestone.startDate)} - ${_formatDate(milestone.endDate)}',
                  '${milestone.description ?? 'No description'}\n'
                      '${milestone.phase != null ? 'Phase: ${milestone.phase}\n' : ''}'
                      '${milestone.completionPercentage != null ? 'Progress: ${milestone.completionPercentage}%\n' : ''}'
                      '${milestone.deliverables != null ? 'Deliverables: ${milestone.deliverables}' : ''}',
                  isCompleted,
                  isLast: isLast,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Reports History Section
  Widget _buildReports() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Reports',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
          SizedBox(height: 20),

          if (_isLoadingReports)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(
                  color: Colors.deepOrangeAccent,
                ),
              ),
            )
          else if (_dailyReports.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No daily reports available for this project',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ..._dailyReports.map((report) {
              final employeeName = report.employee != null
                  ? report.employee!['name'] ?? 'Unknown'
                  : 'Unknown';
              final description =
                  report.description != null &&
                      report.description!.isNotEmpty
                  ? ' - ${report.description}'
                  : '';

              return Column(
                children: [
                  _buildReportItem(
                    '${report.title}$description',
                    '${_formatDate(report.date)} by $employeeName',
                    'Submitted',
                    Colors.green,
                  ),
                  SizedBox(height: 15),
                ],
              );
            }),
        ],
      ),
    );
  }

  // Members Section
  Widget _buildMembers() {
    // Extract unique employees from daily reports
    final Map<int, Map<String, dynamic>> uniqueEmployees =
        {};
    for (var report in _dailyReports) {
      if (report.employee != null) {
        final empId = report.employee!['id'];
        if (empId != null &&
            !uniqueEmployees.containsKey(empId)) {
          uniqueEmployees[empId] = report.employee!;
        }
      }
    }

    final employeesList = uniqueEmployees.values.toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Board',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
          SizedBox(height: 20),

          if (_isLoadingReports)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(
                  color: Colors.deepOrangeAccent,
                ),
              ),
            )
          else if (employeesList.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No team members found for this project',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              childAspectRatio: 0.75,
              children: employeesList.map((employee) {
                return _buildTeamMember(
                  employee['name'] ?? 'Unknown',
                  'Team Member',
                );
              }).toList(),
            ),

          SizedBox(height: 40),

          // Employee Working Hours
          Text(
            'Employees Working on Project',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
          SizedBox(height: 20),

          if (_isLoadingReports)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(
                  color: Colors.deepOrangeAccent,
                ),
              ),
            )
          else if (employeesList.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No employee data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...employeesList.asMap().entries.map((entry) {
              final index = entry.key;
              final employee = entry.value;
              final employeeName =
                  employee['name'] ?? 'Unknown';

              // Count reports by this employee
              final reportsCount = _dailyReports
                  .where(
                    (report) =>
                        report.employee?['id'] ==
                        employee['id'],
                  )
                  .length;

              return Column(
                children: [
                  _buildWorkedEmployee(
                    employeeName,
                    reportsCount *
                        8, // Estimate: 8 hours per report
                    employeesList.isNotEmpty
                        ? (_dailyReports.length * 8) ~/
                              employeesList.length
                        : 100,
                  ),
                  if (index < employeesList.length - 1)
                    SizedBox(height: 15),
                ],
              );
            }),
        ],
      ),
    );
  }

  // Tasks Section
  Widget _buildTasks() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Tasks',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
          SizedBox(height: 20),
          _buildTaskItem(
            'Implement payment gateway',
            'Sarah Johnson',
            'Completed',
            Colors.green,
            'High',
          ),
          SizedBox(height: 15),
          _buildTaskItem(
            'Design user dashboard',
            'Michael Chen',
            'In Progress',
            Colors.orange,
            'High',
          ),
          SizedBox(height: 15),
          _buildTaskItem(
            'Setup database schema',
            'Emily Rodriguez',
            'Completed',
            Colors.green,
            'High',
          ),
          SizedBox(height: 15),
          _buildTaskItem(
            'Create API endpoints',
            'David Kim',
            'In Progress',
            Colors.orange,
            'Medium',
          ),
          SizedBox(height: 15),
          _buildTaskItem(
            'Write unit tests',
            'Lisa Anderson',
            'Pending',
            Colors.grey,
            'Medium',
          ),
          SizedBox(height: 15),
          _buildTaskItem(
            'Deploy to staging',
            'James Wilson',
            'Pending',
            Colors.grey,
            'Low',
          ),
          SizedBox(height: 15),
          _buildTaskItem(
            'User acceptance testing',
            'Maria Garcia',
            'In Progress',
            Colors.orange,
            'High',
          ),
          SizedBox(height: 15),
          _buildTaskItem(
            'Analytics integration',
            'Robert Taylor',
            'Completed',
            Colors.green,
            'Low',
          ),
        ],
      ),
    );
  }

  // Facts Section
  Widget _buildFacts() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Facts & Statistics',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
          SizedBox(height: 20),
          _buildInfoItem('Total Budget: \$450,000'),
          SizedBox(height: 15),
          _buildInfoItem('Budget Spent: \$337,500 (75%)'),
          SizedBox(height: 15),
          _buildInfoItem('Total Team Members: 10'),
          SizedBox(height: 15),
          _buildInfoItem('Total Working Hours: 12,800 hrs'),
          SizedBox(height: 15),
          _buildInfoItem(
            'Average Hours per Member: 1,280 hrs',
          ),
          SizedBox(height: 15),
          _buildInfoItem('Project Duration: 11 months'),
          SizedBox(height: 15),
          _buildInfoItem('Completed Tasks: 145 of 200'),
          SizedBox(height: 15),
          _buildInfoItem('Success Rate: 72.5%'),
          SizedBox(height: 15),
          _buildInfoItem('Bug Reports: 87'),
          SizedBox(height: 15),
          _buildInfoItem('Bugs Fixed: 79 (90.8%)'),
          SizedBox(height: 15),
          _buildInfoItem('Code Commits: 2,456'),
          SizedBox(height: 15),
          _buildInfoItem('Pull Requests: 342'),
          SizedBox(height: 15),
          _buildInfoItem('Code Reviews: 298'),
          SizedBox(height: 15),
          _buildInfoItem('Client Meetings: 24'),
          SizedBox(height: 15),
          _buildInfoItem('Sprint Cycles Completed: 18'),
          SizedBox(height: 15),
          _buildInfoItem('Documentation Pages: 156'),
          SizedBox(height: 15),
          _buildInfoItem('Test Coverage: 87%'),
          SizedBox(height: 15),
          _buildInfoItem('Performance Score: 94/100'),
          SizedBox(height: 15),
          _buildInfoItem('Customer Satisfaction: 4.7/5.0'),
        ],
      ),
    );
  }

  // Helper Widgets

  Widget _buildInfoItem(String text) {
    return Row(
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
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepOrangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepOrangeAccent.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
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

  Widget _buildWorkedEmployee(
    String name,
    int hoursWorked,
    int totalHours,
  ) {
    double progress = hoursWorked / totalHours;

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(
                context,
              ).textTheme.titleMedium?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            color: Colors.deepOrangeAccent,
            minHeight: 8,
          ),
        ),
        SizedBox(width: 15),
        SizedBox(
          width: 70,
          child: Text(
            '$hoursWorked hrs',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMember(String name, String jobTitle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.deepOrangeAccent,
          child: Text(
            name.substring(0, 1),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(
              context,
            ).textTheme.titleMedium?.color,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 5),
        Text(
          jobTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

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

  Widget _buildTaskItem(
    String taskName,
    String assignedTo,
    String status,
    Color statusColor,
    String priority,
  ) {
    Color priorityColor = priority == 'High'
        ? Colors.red
        : priority == 'Medium'
        ? Colors.orange
        : Colors.blue;

    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  taskName,
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
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).iconTheme.color,
              ),
              SizedBox(width: 5),
              Text(
                assignedTo,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String date,
    String description,
    bool isCompleted, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator column
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.deepOrangeAccent
                    : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? Colors.deepOrangeAccent
                      : Colors.grey.shade400,
                  width: 3,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ),
        SizedBox(width: 15),
        // Timeline content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? Colors.deepOrangeAccent
                        : Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
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
        ),
      ],
    );
  }
}
