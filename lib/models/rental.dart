import 'package:cloud_firestore/cloud_firestore.dart';

/*
int status
1 = requested
2 = accepted
3 = active
4 = returned
5 = completed
 */

class Rental {
  int status; // true if item is still in request mode, false otherwise
  DocumentReference item; // user ID of user who created the item
  DocumentReference owner;
  DocumentReference renter;
  DateTime start;
  DateTime end;
  DocumentReference chat;

  Rental({
    this.status,
    this.item,
    this.owner,
    this.renter,
    this.start,
    this.end,
    this.chat,
  });

  Rental.fromMap(Map<String, dynamic> data)
      : this(
    status: data['status'],
    item: data['item'],
    owner: data['owner'],
    renter: data['renter'],
    start: data['start'],
    end: data['end'],
    chat: data['chat'],
  );
}
