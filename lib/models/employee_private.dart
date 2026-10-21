import 'job_level.dart';
import 'job_position.dart';
import 'organization.dart';
import 'user.dart';

class EmployeePrivate {
  final String id;
  final String? organization_id;
  final String? job_position_id;
  final String? job_level_id;
  final String? employment_status;
  final DateTime? join_date;
  final DateTime? end_date;
  final String? approval_line_auth_id;
  final String? manager_line_auth_id;
  final String auth_id;
  final Organization? organization;
  final JobPosition? job_position;
  final JobLevel? job_level;
  final User? approval_line;
  final User? manager;

  EmployeePrivate({
    required this.id,
    this.organization_id,
    this.job_position_id,
    this.job_level_id,
    this.employment_status,
    this.join_date,
    this.end_date,
    this.approval_line_auth_id,
    this.manager_line_auth_id,
    required this.auth_id,
    this.organization,
    this.job_position,
    this.job_level,
    this.approval_line,
    this.manager,
  });

  //map -> EmployeePrivate
  factory EmployeePrivate.fromMap(Map<String, dynamic> map) {
    return EmployeePrivate(
      id: map['id'] ?? '',
      organization_id: map['organization_id'],
      job_position_id: map['job_position_id'],
      job_level_id: map['job_level_id'],
      employment_status: map['employment_status'],
      join_date: map['join_date'] != null
          ? DateTime.parse(map['join_date'])
          : null,
      end_date: map['end_date'] != null
          ? DateTime.parse(map['end_date'])
          : null,
      approval_line_auth_id: map['approval_line_auth_id'],
      manager_line_auth_id: map['manager_line_auth_id'],
      auth_id: map['auth_id'] ?? '',
      organization: map['organization'] != null
          ? Organization.fromMap(map['organization'])
          : null,
      job_position: map['job_position'] != null
          ? JobPosition.fromMap(map['job_position'])
          : null,
      job_level: map['job_level'] != null
          ? JobLevel.fromMap(map['job_level'])
          : null,
      approval_line: map['approval_line'] != null
          ? User.fromMap(map['approval_line'])
          : null,
      manager: map['manager'] != null
          ? User.fromMap(map['manager'])
          : null,
    );
  }

  //EmployeePrivate -> map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organization_id': organization_id,
      'job_position_id': job_position_id,
      'job_level_id': job_level_id,
      'employment_status': employment_status,
      'join_date': join_date?.toIso8601String(),
      'end_date': end_date?.toIso8601String(),
      'approval_line_auth_id': approval_line_auth_id,
      'manager_line_auth_id': manager_line_auth_id,
      'auth_id': auth_id,
      'organization': organization?.toMap(),
      'job_position': job_position?.toMap(),
      'job_level': job_level?.toMap(),
      'approval_line': approval_line?.toMap(),
      'manager': manager?.toMap(),  
    };
  }
}
