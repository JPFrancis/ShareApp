import 'package:shareapp/models/item.dart';

class User {
  String id;
  String photoUrl;
  String displayName;
  String email;
  List<Item> myListings;
  List<Item> myRentals;

  User({
    this.id,
    this.photoUrl,
    this.displayName,
    this.email,
    this.myListings,
    this.myRentals,
  });

  User.fromMap(Map<String, dynamic> data, String id)
      : this(
          id: id,
          photoUrl: data['imageURL'],
          displayName: data['displayName'],
          email: data['email'],
          myListings: data['myListings'],
          myRentals: data['myRentals'],
        );

  User.copy(User other)
      : this(
          id: other.id,
          photoUrl: other.photoUrl,
          displayName: other.displayName,
          email: other.email,
          myListings: other.myListings.toList(),
          myRentals: other.myRentals.toList(),
        );

  User fromUser(User other) {
    return new User(
      id: other.id,
      photoUrl: other.photoUrl,
      displayName: other.displayName,
      email: other.email,
      myListings: other.myListings.toList(),
      myRentals: other.myRentals.toList(),
    );
  }
}
