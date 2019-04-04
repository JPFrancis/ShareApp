import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  String id; // doc id for firestore
  DocumentReference creator; // user ID of user who created the item
  String creatorID;
  String name;
  String description;
  String type;
  String condition;
  int price;
  int numImages;
  List images;
  GeoPoint location;

  Item({
    this.id,
    this.creator,
    this.creatorID,
    this.name,
    this.description,
    this.type,
    this.condition,
    this.price,
    this.numImages,
    this.images,
    this.location,
  });

  Item.fromMap(Map<String, dynamic> data, String id)
      : this(
          id: id,
          creator: data['creator'],
          creatorID: data['creatorID'],
          name: data['name'],
          description: data['description'],
          type: data['type'],
          condition: data['condition'],
          price: data['price'],
          numImages: data['numImages'],
          images: data['images'],
          location: data['location'],
        );

  Item.fromMapNoID(Map<String, dynamic> data)
      : this(
          id: data['id'],
          creator: data['creator'],
          creatorID: data['creatorID'],
          name: data['name'],
          description: data['description'],
          type: data['type'],
          condition: data['condition'],
          price: data['price'],
          numImages: data['numImages'],
          images: data['images'],
          location: data['location'],
        );

  Item.copy(Item other)
      : this(
          id: other.id,
          creator: other.creator,
          creatorID: other.creatorID,
          name: other.name,
          description: other.description,
          type: other.type,
          condition: other.condition,
          price: other.price,
          numImages: other.numImages,
          images: other.images.toList(),
          location: other.location,
        );

  bool compare(Item other) {
    return this.name == other.name &&
        this.description == other.description &&
        this.type == other.type &&
        this.condition == other.condition &&
        this.price == other.price &&
        this.location == other.location;
  }

  Item fromItem(Item other) {
    return new Item(
      id: other.id,
      creator: other.creator,
      creatorID: other.creatorID,
      name: other.name,
      description: other.description,
      type: other.type,
      condition: other.condition,
      price: other.price,
      numImages: other.numImages,
      images: other.images.toList(),
      location: other.location,
    );
  }
}
