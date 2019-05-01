import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String id;
  String photoUrl;
  String displayName;
  String email;
  List<DocumentReference> items;
  List<DocumentReference> rentals;

  User({
    this.id,
    this.photoUrl,
    this.displayName,
    this.email,
    this.items,
    this.rentals,
  });

  User.fromMap(Map<String, dynamic> data, String id)
      : this(
          id: id,
          photoUrl: data['imageURL'],
          displayName: data['name'],
          email: data['email'],
          items: data['myListings'],
          rentals: data['myRentals'],
        );

  User.copy(User other)
      : this(
          id: other.id,
          photoUrl: other.photoUrl,
          displayName: other.displayName,
          email: other.email,
          items: other.items.toList(),
          rentals: other.rentals.toList(),
        );

  User fromUser(User other) {
    return new User(
      id: other.id,
      photoUrl: other.photoUrl,
      displayName: other.displayName,
      email: other.email,
      items: other.items.toList(),
      rentals: other.rentals.toList(),
    );
  }
}
