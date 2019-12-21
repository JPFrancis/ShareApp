import 'package:cloud_firestore/cloud_firestore.dart';

/*
declined:
true = declined
false = cancelled
null = neither
 */

/*
int status
1 = requested
2 = accepted
3 = active'
4 = returned
5 = cancelled
*/

/*
0) renter has proposed time - burden of accept is on owner.
  Entered when renter proposes new time
1) owner has proposed time - burden of accept is on renter
  Entered when owner proposes new time
2) accepted - when the rental request is agreed upon, can be done by either
  renter or owner. Before the pickup window starts
3) active - the actual renting is taking place including pickup window.
  Occurs when rental pickup start is after current time.
4) Rental is finished. Starts when current time hits rentalEnd.
5) Rental is cancelled
*/

class Rental {
  int status; // true if item is still in request mode, false otherwise
  DocumentReference item; // user ID of user who created the item
  DocumentReference owner;
  DocumentReference renter;
  DateTime start;
  DateTime end;

  Rental({
    this.status,
    this.item,
    this.owner,
    this.renter,
    this.start,
    this.end,
  });

  Rental.fromMap(Map<String, dynamic> data)
      : this(
          status: data['status'],
          item: data['item'],
          owner: data['owner'],
          renter: data['renter'],
          start: data['start'],
          end: data['end'],
        );
}
