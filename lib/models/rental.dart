import 'package:cloud_firestore/cloud_firestore.dart';

class Rental {
  String id; // doc id for firestore
  bool isRequest; // true if item is still in request mode, false otherwise
  DocumentReference item; // user ID of user who created the item
  DocumentReference owner;
  DocumentReference renter;
  DateTime start;
  DateTime end;
  DocumentReference chat;

  Rental({
    this.id,
    this.isRequest,
    this.item,
    this.owner,
    this.renter,
    this.start,
    this.end,
    this.chat,
  });

  Rental.fromMap(Map<String, dynamic> data, String id)
      : this(
    id: id,
    isRequest: data['isRequest'],
    item: data['item'],
    owner: data['owner'],
    renter: data['renter'],
    start: data['start'],
    end: data['end'],
    chat: data['chat'],
  );

  Rental.fromMapNoID(Map<String, dynamic> data)
      : this(
    id: data['id'],
    isRequest: data['isRequest'],
    item: data['item'],
    owner: data['owner'],
    renter: data['renter'],
    start: data['start'],
    end: data['end'],
    chat: data['chat'],
  );
}
