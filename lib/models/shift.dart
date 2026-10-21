class Shift{
  String id;
  String name;
  String startTime;
  String endTime;
  bool isWorkingDay;
  bool requireHrApproval;
  String? code;
  String? color;

  Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.isWorkingDay,
    required this.requireHrApproval,
    this.code,
    this.color,
  });

  // Map -> Shift
  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] as String,  
    name: map['name'] as String,
    startTime: map['start_time'] as String,
    endTime: map['end_time'] as String,
    isWorkingDay: map['is_working_day'] as bool,
    requireHrApproval: map['require_hr_approval'] as bool,
    code: map['code'] as String?,
    color: map['color'] as String?,
    );
  }

  // Shift -> Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'is_working_day': isWorkingDay,
      'require_hr_approval': requireHrApproval,
      'code': code,
      'color': color,
    };
  }
}