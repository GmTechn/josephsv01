class AppUser {
  final int? id;
  final String? fname;
  final String? lname;
  final String? photoPath;

  AppUser({this.id, this.fname, this.lname, this.photoPath});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fname': fname,
      'lname': lname,
      'photoPath': photoPath ?? '',
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      fname: map['fname'],
      lname: map['lname'],
      photoPath: map['photoPath'],
    );
  }
}
