/*
  Address fields:
  street
  city
  state
  zip
 */

import 'package:shareapp/models/user.dart';

class UserEdit {
  String avatar;
  String name;
  String description;
  String gender;
  String email;
  String phoneNum;
  DateTime birthday;
  Map address;

  UserEdit({
    this.avatar,
    this.name,
    this.description,
    this.gender,
    this.email,
    this.phoneNum,
    this.birthday,
    this.address,
  });

  UserEdit.fromUser(User user)
      : this(
          avatar: user.avatar,
          name: user.name,
          description: user.description,
          gender: user.gender,
          email: user.email,
          phoneNum: user.phoneNum,
          birthday: user.birthday,
          address: user.address,
        );

  UserEdit.copy(UserEdit other)
      : this(
          avatar: other.avatar,
          name: other.name,
          description: other.description,
          gender: other.gender,
          email: other.email,
          phoneNum: other.phoneNum,
          birthday: other.birthday,
          address: other.address,
        );

  bool compare(UserEdit other) {
    return this.avatar == other.avatar &&
        this.name == other.name &&
        this.description == other.description &&
        this.gender == other.gender &&
        this.email == other.email &&
        this.phoneNum == other.phoneNum &&
        this.birthday == other.birthday &&
        this.address == other.address;
  }

  UserEdit fromUser(UserEdit other) {
    return UserEdit(
      avatar: other.avatar,
      name: other.name,
      description: other.description,
      gender: other.gender,
      email: other.email,
      phoneNum: other.phoneNum,
      birthday: other.birthday,
      address: other.address,
    );
  }
}
