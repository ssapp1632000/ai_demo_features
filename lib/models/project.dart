/// Project model representing a work project
class Project {
  final int id;
  final String title;
  final String? projectCode;
  final String? description;
  final String? location; // Derived from address.city and address.district
  final DateTime? startDate;
  final String? status;
  final String? totalDurationWorked;
  final String? totalHours;
  final String? imageUrl;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Project({
    required this.id,
    required this.title,
    this.projectCode,
    this.description,
    this.location,
    this.startDate,
    this.status,
    this.totalDurationWorked,
    this.totalHours,
    this.imageUrl,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Extract location from address object
    String? location;
    if (json['address'] != null) {
      final address = json['address'] as Map<String, dynamic>;
      final city = address['city'];
      final district = address['district'];
      if (city != null && district != null) {
        location = '$district, $city';
      } else if (city != null) {
        location = city;
      } else if (district != null) {
        location = district;
      }
    }

    return Project(
      id: json['id'],
      title: json['title'],
      projectCode: json['projectCode'],
      description: json['description'],
      location: location,
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      status: json['status'],
      totalDurationWorked: json['totalDurationWorked'],
      totalHours: json['totalHours'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'projectCode': projectCode,
      'description': description,
      'location': location,
      'startDate': startDate?.toIso8601String(),
      'status': status,
      'totalDurationWorked': totalDurationWorked,
      'totalHours': totalHours,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Milestone model representing project phases
class Milestone {
  final int id;
  final String title;
  final String? description;
  final String? phase;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final String? deliverables;
  final int? sequence;
  final double? completionPercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Milestone({
    required this.id,
    required this.title,
    this.description,
    this.phase,
    this.startDate,
    this.endDate,
    this.status,
    this.deliverables,
    this.sequence,
    this.completionPercentage,
    this.createdAt,
    this.updatedAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      phase: json['phase'],
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: json['status'],
      deliverables: json['deliverables'],
      sequence: json['sequence'],
      completionPercentage: json['completionPercentage']?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'phase': phase,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'deliverables': deliverables,
      'sequence': sequence,
      'completionPercentage': completionPercentage,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Daily Report model
class DailyReport {
  final int id;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final Map<String, dynamic>? employee;
  final Map<String, dynamic>? project;

  DailyReport({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.createdAt,
    this.employee,
    this.project,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      employee: json['employee'],
      project: json['project'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'employee': employee,
      'project': project,
    };
  }
}

/// Employee model representing an employee in the system
class Employee {
  final int id;
  final String employeeCode;
  final String? fullName;
  final String email;
  final String? phone;
  final String? designation;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? nationality;
  final String? professionalImageUrl;
  final bool isActive;
  final DateTime? dateJoined;
  final Map<String, dynamic>? department;
  final List<dynamic>? roles;

  Employee({
    required this.id,
    required this.employeeCode,
    this.fullName,
    required this.email,
    this.phone,
    this.designation,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.professionalImageUrl,
    required this.isActive,
    this.dateJoined,
    this.department,
    this.roles,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      employeeCode: json['employeeCode'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      designation: json['designation'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      gender: json['gender'],
      nationality: json['nationality'],
      professionalImageUrl: json['professionalImageUrl'],
      isActive: json['isActive'] ?? true,
      dateJoined: json['dateJoined'] != null
          ? DateTime.parse(json['dateJoined'])
          : null,
      department: json['department'],
      roles: json['roles'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'designation': designation,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'nationality': nationality,
      'professionalImageUrl': professionalImageUrl,
      'isActive': isActive,
      'dateJoined': dateJoined?.toIso8601String(),
      'department': department,
      'roles': roles,
    };
  }

  // Helper method to get department name
  String get departmentName {
    if (department != null && department!['name'] != null) {
      return department!['name'];
    }
    return 'N/A';
  }

  // Helper method to get primary role name
  String get roleName {
    if (roles != null && roles!.isNotEmpty) {
      final firstRole = roles![0];
      if (firstRole['role'] != null && firstRole['role']['name'] != null) {
        return firstRole['role']['name'];
      }
    }
    return 'N/A';
  }
}
