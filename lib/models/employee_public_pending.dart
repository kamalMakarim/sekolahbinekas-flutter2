class EmployeePublicPending {
  final String id;
  final String auth_id;
  final String first_name;
  String? last_name;
  String? place_of_birth;
  String? date_of_birth;
  String? gender;
  String? martial_status;
  String? blood_type;
  String? religion;
  String? nik;
  bool? isApproved;

  EmployeePublicPending({
    required this.id,
    required this.auth_id,
    required this.first_name,
    this.last_name,
    this.place_of_birth,
    this.date_of_birth,
    this.gender,
    this.martial_status,
    this.blood_type,
    this.religion,
    this.nik,
    this.isApproved,
  });

  //map -> EmployeePublicPending
  factory EmployeePublicPending.fromMap(Map<String, dynamic> map) {
    return EmployeePublicPending(
      id: map['id'] as String,
      auth_id: map['auth_id'] as String,
      first_name: map['first_name'] as String,
      last_name: map['last_name'] as String?,
      place_of_birth: map['place_of_birth'] as String?,
      date_of_birth: map['date_of_birth'] as String?,
      gender: map['gender'] as String?,
      martial_status: map['martial_status'] as String?,
      blood_type: map['blood_type'] as String?,
      religion: map['religion'] as String?,
      nik: map['nik'] as String?,
      isApproved: map['is_approved'] as bool? ?? map['isApproved'] as bool?,
    );
  }

  //EmployeePublicPending -> map
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'auth_id': auth_id,
      'first_name': first_name,
      'last_name': last_name ?? '',
      'place_of_birth': place_of_birth ?? '',
      'date_of_birth': date_of_birth ?? '',
      'gender': gender ?? '',
      'martial_status': martial_status ?? '',
      'blood_type': blood_type ?? '',
      'religion': religion ?? '',
      'nik': nik ?? '',
      'is_approved': isApproved ?? false,
    };
  }
}
