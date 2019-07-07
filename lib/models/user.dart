class User {
  String avatar;
  String name;
  String description;
  String gender;
  String email;
  String phoneNum;
  DateTime birthday;

  User({
    this.avatar,
    this.name,
    this.description,
    this.gender,
    this.email,
    this.phoneNum,
    this.birthday,
  });

  User.fromMap(Map<String, dynamic> data, DateTime birthdayAsDateTime)
      : this(
          avatar: data['avatar'],
          name: data['name'],
          description: data['description'],
          gender: data['gender'],
          email: data['email'],
          phoneNum: data['phoneNum'],
          birthday: birthdayAsDateTime,
        );

  User.copy(User other)
      : this(
          avatar: other.avatar,
          name: other.name,
          description: other.description,
          gender: other.gender,
          email: other.email,
          phoneNum: other.phoneNum,
          birthday: other.birthday,
        );

  bool compare(User other) {
    return this.avatar == other.avatar &&
        this.name == other.name &&
        this.description == other.description &&
        this.gender == other.gender &&
        this.email == other.email &&
        this.phoneNum == other.phoneNum &&
        this.birthday == other.birthday;
  }

  User fromUser(User other) {
    return User(
      avatar: other.avatar,
      name: other.name,
      description: other.description,
      gender: other.gender,
      email: other.email,
      phoneNum: other.phoneNum,
      birthday: other.birthday,
    );
  }
}
