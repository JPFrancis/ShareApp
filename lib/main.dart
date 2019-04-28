import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/login/root_page.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/home_page.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/rentals/item_request.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShareApp',
      theme: ThemeData(
        primarySwatch: Colors.red,
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
                    itemID: args.itemID,
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
                    rentalID: args.rentalID,
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
  final String itemID;

  ItemDetailArgs(
    this.itemID,
  );
}

class ItemEditArgs {
  final Item item;

  ItemEditArgs(
    this.item,
  );
}

class ItemRequestArgs {
  final String itemID;

  ItemRequestArgs(
    this.itemID,
  );
}

class RentalDetailArgs {
  final String rentalID;

  RentalDetailArgs(
    this.rentalID,
  );
}

class ChatArgs {
  final String rentalID;

  ChatArgs(
    this.rentalID,
  );
}
