import 'package:cloud_firestore/cloud_firestore.dart';

/*
'Tool',
'Leisure',
'Home',
'Equipment',
'Other',
 */

/*
int condition
1 = lightly used
2 = good
3 = fair
4 = has character
 */

/*
bool status
true = active
false = inactive
 */

class Item {
  String id; // doc id for firestore
  bool status;
  DocumentReference creator; // user ID of user who created the item
  String name;
  String description;
  String type;
  String condition;
  String policy;
  double rating;
  double numRatings;
  int price;
  int numImages;
  List images;
  Map<String, dynamic> location;
  DocumentReference rental;

  Item({
    this.id,
    this.status,
    this.creator,
    this.name,
    this.description,
    this.type,
    this.condition,
    this.policy,
    this.rating,
    this.numRatings,
    this.price,
    this.numImages,
    this.images,
    this.location,
    this.rental,
  });

  Item.fromMap(Map<String, dynamic> data)
      : this(
          id: data['id'],
          status: data['status'],
          creator: data['creator'],
          name: data['name'],
          description: data['description'],
          type: data['type'],
          condition: data['condition'],
          policy: data['policy'],
          rating: data['rating'].toDouble(),
          numRatings: data['numRatings'].toDouble(),
          price: data['price'],
          numImages: data['numImages'],
          images: data['images'],
          location: data['location'],
          rental: data['rental'],
        );

  Item.copy(Item other)
      : this(
          id: other.id,
          status: other.status,
          creator: other.creator,
          name: other.name,
          description: other.description,
          type: other.type,
          condition: other.condition,
          policy: other.policy,
          rating: other.rating,
          numRatings: other.numRatings,
          price: other.price,
          numImages: other.numImages,
          images: other.images.toList(),
          location: other.location,
          rental: other.rental,
        );

  bool compare(Item other) {
    return this.name == other.name &&
        this.description == other.description &&
        this.type == other.type &&
        this.condition == other.condition &&
        this.policy == other.policy &&
        this.price == other.price &&
        this.location == other.location;
  }

  Item fromItem(Item other) {
    return new Item(
      id: other.id,
      status: other.status,
      creator: other.creator,
      name: other.name,
      description: other.description,
      type: other.type,
      condition: other.condition,
      policy: other.policy,
      rating: other.rating,
      numRatings: other.numRatings,
      price: other.price,
      numImages: other.numImages,
      images: other.images.toList(),
      location: other.location,
      rental: other.rental,
    );
  }
}
