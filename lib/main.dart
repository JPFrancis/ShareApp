import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/login/root_page.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/all_items.dart';
import 'package:shareapp/pages/home_page.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/pages/search_results.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/rentals/item_request.dart';
import 'package:shareapp/rentals/new_pickup.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShareApp',
      theme: ThemeData(
        //primarySwatch: Colors.red,
        backgroundColor: Colors.black
      ),
      home: new RootPage(auth: new Auth()),
      //initialRoute: RootPage.routeName,
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
                    initRentalDS: args.initRentalDS,
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
                    rentalDS: args.rentalDS,
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

          case AllItems.routeName:
            {
              final AllItemsArgs args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return AllItems();
                },
              );
            }
          case SearchResults.routeName:
            {
              final SearchResults args = settings.arguments;

              return MaterialPageRoute(
                builder: (context) {
                  return SearchResults(
                    searchList: args.searchList,
                    searchQuery: args.searchQuery,
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
  final DocumentSnapshot initRentalDS;

  RentalDetailArgs(this.initRentalDS);
}

class ChatArgs {
  final DocumentSnapshot rentalDS;

  ChatArgs(this.rentalDS);
}

class NewPickupArgs {
  final String rentalID;
  final bool isRenter;

  NewPickupArgs(this.rentalID, this.isRenter);
}

class AllItemsArgs {
  AllItemsArgs();
}

class SearchResultsArgs {
  final List<DocumentSnapshot> searchList;
  final String searchQuery;

  SearchResultsArgs(this.searchList, this.searchQuery);
}
