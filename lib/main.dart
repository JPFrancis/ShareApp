import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/login/root_page.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/all_reviews.dart';
import 'package:shareapp/pages/home_page.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/pages/item_filter.dart';
import 'package:shareapp/pages/profile_page.dart';
import 'package:shareapp/pages/search_page.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/rentals/item_request.dart';
import 'package:shareapp/rentals/new_pickup.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/auth.dart';
import 'package:shareapp/models/user.dart';

void main() => runApp(MyApp());

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
                  );
                },
                fullscreenDialog: true,
              );
            }

          case ItemRequest.routeName:
            {
              final ItemRequestArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return ItemRequest(
                    itemID: args.itemID,
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
                    otherUser: args.otherUser,
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

          case ItemFilter.routeName:
            {
              final ItemFilterArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return ItemFilter(
                    typeFilter: args.filter,
                  );
                },
              );
            }
          case SearchPage.routeName:
            {
              final SearchResultsArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return SearchPage();
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
                    initUserDS: args.userDS,
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

  ItemEditArgs(this.item);
}

class ItemRequestArgs {
  final String itemID;

  ItemRequestArgs(this.itemID);
}

class RentalDetailArgs {
  final String rentalID;

  RentalDetailArgs(this.rentalID);
}

class ChatArgs {
  final DocumentSnapshot otherUser;

  ChatArgs(this.otherUser);
}

class NewPickupArgs {
  final String rentalID;
  final bool isRenter;

  NewPickupArgs(this.rentalID, this.isRenter);
}

class ItemFilterArgs {
  final String filter;

  ItemFilterArgs(this.filter);
}

class SearchResultsArgs {
  SearchResultsArgs();
}

class AllReviewsArgs {
  final DocumentSnapshot itemDS;

  AllReviewsArgs(this.itemDS);
}

class ProfilePageArgs {
  final DocumentSnapshot userDS;

  ProfilePageArgs(this.userDS);
}
