import 'package:cloud_firestore/cloud_firestore.dart';

/*
int status
1 = requested
2 = accepted
3 = active
4 = returned
5 = completed
 */

/*
0) renter has proposed time - burden of accept is on owner
1) owner has proposed time - burden of accept is on renter
2) accepted - the owner has accepted the request. the renter will be notified, 
  and both parties will be instructed to exchange the item
3) active - the actual renting is taking place. The renter has the item now. 
  Phase 3 is entered when pickup window ends
4) returned - the renting has finished, and the item has been returned to the 
  owner. the renter will write a review. Entered when duration ends
5) completed - when the whole transaction has been completed. the item will be 
  moved into 'completed' phase when the renter has finished the review and the 
  owner has inspected the item for damage, missing parts etc (so the owner has 
  to confirm that the item was returned in good shape). rentals marked 
  'completed' will be stored in an archive
6) abandoned - the request was never accepted, either the user cancelled the
  request or the owner declined the request. not sure if we want to store
  abandoned rentals
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
