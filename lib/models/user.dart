class User {
  final String username;
  final String fullName;
  final String password;

  User({
    required this.username,
    required this.fullName,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'fullName': fullName,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      fullName: map['fullName'],
      password: map['password'],
    );
  }
}