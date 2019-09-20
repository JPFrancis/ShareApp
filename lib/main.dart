import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shareapp/login/root_page.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/all_reviews.dart';
import 'package:shareapp/pages/home_page.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/pages/profile_page.dart';
import 'package:shareapp/pages/search_page.dart';
import 'package:shareapp/pages/transactions_page.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/rentals/new_pickup.dart';
import 'package:shareapp/rentals/rental_calendar.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/auth.dart';
import 'package:shareapp/services/const.dart';

//void main() => runApp(MyApp());

void main() {
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShareApp',
      theme: ThemeData(
        backgroundColor: Colors.black,
        primaryColor: Color(0xff007f6e),
        accentColor: Color(0xff007f6e),
      ),
      home: new RootPage(auth: new Auth()),
      initialRoute: '/',
      //RootPage.routeName,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case HomePage.routeName:
            {
              final HomePageArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return HomePage(
                    auth: args.auth,
                    firebaseUser: args.firebaseUser,
                    onSignOut: args.onSignOut,
                  );
                },
              );
            }

          case ItemDetail.routeName:
            {
              final ItemDetailArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return ItemDetail(
                    initItemDS: args.initItemDS,
                  );
                },
              );
            }

          case ItemEdit.routeName:
            {
              final ItemEditArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return ItemEdit(
                    item: args.item,
                    itemId: args.itemId,
                  );
                },
                fullscreenDialog: true,
              );
            }

          case RentalDetail.routeName:
            {
              final RentalDetailArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return RentalDetail(
                    rentalID: args.rentalID,
                  );
                },
              );
            }

          case Chat.routeName:
            {
              final ChatArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return Chat(
                    otherUserID: args.otherUserID,
                  );
                },
              );
            }

          case NewPickup.routeName:
            {
              final NewPickupArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return NewPickup(
                    rentalID: args.rentalID,
                    isRenter: args.isRenter,
                  );
                },
              );
            }

          case SearchPage.routeName:
            {
              final SearchPageArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return SearchPage(
                    typeFilter: args.typeFilter,
                    showSearch: args.showSearch,
                  );
                },
              );
            }

          case AllReviews.routeName:
            {
              final AllReviewsArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return AllReviews(
                    itemDS: args.itemDS,
                  );
                },
              );
            }

          case ProfilePage.routeName:
            {
              final ProfilePageArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return ProfilePage(
                    userID: args.userID,
                  );
                },
              );
            }

          case RentalCalendar.routeName:
            {
              final RentalCalendarArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return RentalCalendar(
                    itemDS: args.itemDS,
                  );
                },
              );
            }
          case TransactionsPage.routeName:
            {
              final TransactionsPageArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return TransactionsPage(
                    filter: args.filter,
                    person: args.person,
                  );
                },
              );
            }
        }
      },
    );
  }
}

class HomePageArgs {
  final BaseAuth auth;
  final FirebaseUser firebaseUser;
  final VoidCallback onSignOut;

  HomePageArgs(this.auth, this.firebaseUser, this.onSignOut);
}

class ItemDetailArgs {
  final DocumentSnapshot initItemDS;

  ItemDetailArgs(this.initItemDS);
}

class ItemEditArgs {
  final Item item;
  final String itemId;

  ItemEditArgs(this.item, this.itemId);
}

class ItemRequestArgs {
  final String itemID;
  final DateTime startDate;

  ItemRequestArgs(this.itemID, this.startDate);
}

class RentalDetailArgs {
  final String rentalID;

  RentalDetailArgs(this.rentalID);
}

class ChatArgs {
  final String otherUserID;

  ChatArgs(this.otherUserID);
}

class NewPickupArgs {
  final String rentalID;
  final bool isRenter;

  NewPickupArgs(this.rentalID, this.isRenter);
}

class SearchPageArgs {
  final String typeFilter;
  final bool showSearch;

  SearchPageArgs(this.typeFilter, this.showSearch);
}

class AllReviewsArgs {
  final DocumentSnapshot itemDS;

  AllReviewsArgs(this.itemDS);
}

class ProfilePageArgs {
  final String userID;

  ProfilePageArgs(this.userID);
}

class RentalCalendarArgs {
  final DocumentSnapshot itemDS;

  RentalCalendarArgs(this.itemDS);
}

class TransactionsPageArgs {
  final RentalPhase filter;
  final String person;

  TransactionsPageArgs(this.filter, this.person);
}
