import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/models/current_user.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/functions.dart';

class SearchPage extends StatefulWidget {
  static const routeName = '/searchPage';
  final String typeFilter;
  final bool showSearch;

  SearchPage({Key key, this.typeFilter, this.showSearch}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SearchPageState();
  }
}

class SearchPageState extends State<SearchPage> {
  CurrentUser currentUser;
  Geoflutterfire geo = Geoflutterfire();
  Position currentLocation;

  TextEditingController searchController = TextEditingController();
  bool showSuggestions;
  List<String> recommendedItems = [];
  List<DocumentSnapshot> prefixSnaps = [];
  List<String> prefixList = [];
  List<String> suggestions = [];

  String myUserID;
  String typeFilter;
  String conditionFilter;
  double distanceFilter;
  String sortByFilter;

  bool distanceIsInfinite = true;
  bool pageIsLoading = true;
  bool filterPressed = false;
  bool locIsLoading = false;
  bool isAuthenticated;
  bool showSearch;

  String font = 'Quicksand';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    currentUser = CurrentUser.getModel(context);
    showSearch = widget.showSearch;
    typeFilter = widget.typeFilter;
    showSuggestions = showSearch ? true : false;
    conditionFilter = 'All';
    distanceFilter = 5.0;
    sortByFilter = 'Distance';

    getMyUserID();
    getSuggestions();
    getUserLoc();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void getMyUserID() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    currentLocation = Position(
        latitude: currentUser.currentLocation.latitude,
        longitude: currentUser.currentLocation.longitude);

    if (user != null) {
      isAuthenticated = true;
      myUserID = user.uid;
    } else {
      isAuthenticated = false;
    }
  }

  getUserLoc() async {
    setState(() {
      pageIsLoading = true;
    });

    currentLocation = await getUserLocation();

    if (currentLocation != null) {
      currentUser.updateCurrentLocation(currentLocation);
    } else {
      currentLocation = currentUser.currentLocation;

      showToast('Could not get location. Using last known location.');
    }

    setState(() {
      pageIsLoading = false;
    });
  }

  Future<Null> getSuggestions() async {
    QuerySnapshot querySnapshot = await Firestore.instance
        .collection('items')
        .orderBy('name', descending: false)
        .limit(5)
        .getDocuments();

    if (querySnapshot != null) {
      List<DocumentSnapshot> suggestedItems = querySnapshot.documents;

      suggestedItems.forEach((DocumentSnapshot ds) {
        String name = ds['name'].toLowerCase();

        if (!isAuthenticated || ds['creator'].documentID != myUserID) {
          recommendedItems.add(name);
        }
      });
    }
  }

  handleSearch(String searchText) async {
    searchText.trim().toLowerCase();

    // text field is empty
    if (searchText.length == 0) {
      setState(() {
        prefixSnaps = [];
        prefixList = [];
        suggestions = [];
      });
    }

    // user types in one letter
    else if (/*prefixSnaps.length == 0 &&*/ searchText.length == 1) {
      suggestions = prefixList;
      prefixSnaps = [];

      QuerySnapshot docs = await Firestore.instance
          .collection('items')
          .where('searchKey',
              arrayContains: searchText.substring(0, 1).toLowerCase())
          .getDocuments();

      if (docs != null) {
        docs.documents.forEach((ds) {
          if (!isAuthenticated || ds['creator'].documentID != myUserID) {
            prefixSnaps.add(ds);
          }

          String name = ds['name'].toLowerCase();
          String description = ds['description'].toLowerCase();

          List<String> temp = [];

          temp.addAll(name.split(' '));
          temp.addAll(description.split(' '));

          temp.forEach((str) {
            if (str.startsWith(searchText) && !prefixList.contains(str)) {
              if (!isAuthenticated || ds['creator'].documentID != myUserID) {
                prefixList.add(str);
              }
            }
          });
        });

        prefixList.sort();
        suggestions = prefixList;
      }
    }

    // user types more than one letter
    else {
      suggestions = [];
      prefixList.forEach((str) {
        RegExp regExp = RegExp(r'^' + searchText + r'.*$');
        if (regExp.hasMatch(str) && !suggestions.contains(str)) {
          suggestions.add(str);
        }
      });
    }

    setState(() {});
  }

  void resetFilters() {
    setState(() {
      typeFilter = 'All';
      conditionFilter = 'All';
      distanceFilter = 5.0;
      sortByFilter = 'Alphabetically';
    });
  }

  @override
  Widget build(BuildContext context) {
    handleSearch(searchController.text);

    return Scaffold(
      body: pageIsLoading ? Container() : showBody(),
    );
  }

  Widget showBody() {
    Widget _filters() {
      return Column(
        children: <Widget>[
          SizedBox(
            height: 5.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              typeSelector(),
              conditionSelector(),
            ],
          ),
          Container(height: 5),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: distanceSlider(),
                ),
              ),
              Column(
                children: <Widget>[
                  Checkbox(
                    value: distanceIsInfinite,
                    onChanged: (value) {
                      setState(() {
                        distanceIsInfinite = value;
                      });
                    },
                  ),
                  distanceIsInfinite ? Text('All') : Text('Limit')
                ],
              ),
              Container(
                width: 10,
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: sortBy(),
              ),
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: RaisedButton(
                  onPressed: resetFilters,
                  child: Text('Reset'),
                ),
              ),
            ],
          ),
          Container(height: 5),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 30,
        ),
        searchField(),
        showSuggestions
            ? Container(
                height: 200,
                width: MediaQuery.of(context).size.width,
                child: buildSuggestionsList(),
              )
            : Container(),
        filterPressed ? _filters() : Container(),
        buildItemList(),
      ],
    );
  }

  Widget searchField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 10.0,
        ),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: primaryColor,
            )),
        Expanded(
          child: searchBox(),
        ),
        searchController.text.isEmpty
            ? Container()
            : IconButton(
                onPressed: () {
                  setState(() {
                    searchController.clear();
                    showSuggestions = false;
                    //FocusScope.of(context).requestFocus(FocusNode());
                  });
                },
                icon: Icon(
                  Icons.clear,
                  color: primaryColor,
                ),
              ),
        IconButton(
          icon: Icon(Icons.filter_list, color: primaryColor),
          onPressed: () {
            setState(() {
              filterPressed = !filterPressed;
            });
          },
        ),
      ],
    );
  }

  Widget searchBox() {
    return Container(
      padding: EdgeInsets.only(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 70,
            decoration: new BoxDecoration(
              border: Border(left: BorderSide(color: primaryColor, width: 3)),
            ),
            child: Center(
              child: TextField(
                autofocus: showSearch,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontFamily: 'Quicksand', fontSize: 21),
                keyboardType: TextInputType.text,
                controller: searchController,
                onTap: () {
                  setState(() {
                    showSuggestions = true;
                    filterPressed = false;
                  });
                },
                onSubmitted: (value) {
                  setState(() {
                    showSuggestions = false;
                  });
                },
                onChanged: (value) {
                  setState(() {
                    //handleSearch(value);
                    showSuggestions = true;
                  });
                },
                decoration: InputDecoration(
                  hintStyle: TextStyle(fontFamily: 'Quicksand', fontSize: 20.0),
                  hintText: "Search for an item",
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSuggestionsList() {
    List builderList =
        searchController.text.isEmpty ? recommendedItems : suggestions;

    return ListView.builder(
        itemCount: builderList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              builderList[index],
              style: TextStyle(color: Colors.blueGrey, fontFamily: appFont),
            ),
            /*trailing: IconButton(
              icon: Icon(Icons.keyboard_arrow_up),
              onPressed: () {
                setState(() {
                  searchController.text = builderList[index];
                  searchController.value = TextEditingValue(
                      text: builderList[index],
                      selection: TextSelection.collapsed(
                          offset: builderList[index].length));
                  handleSearch(searchController.text.substring(0, 1));
                });
              },
            ),*/
            onTap: () {
              setState(() {
                searchController.text = builderList[index];
                handleSearch(searchController.text.substring(0, 1));
                showSuggestions = false;
                FocusScope.of(context).requestFocus(FocusNode());
              });
            },
          );
        });
  }

  Widget typeSelector() {
    String hint = 'Type: $typeFilter';
    double padding = 20;

    switch (hint) {
      case 'Tool':
        hint = 'Type: Tools';
        break;
      case 'Home':
        hint = 'Type: Household';
        break;
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
          isDense: true,
          //isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
          ),
          onChanged: (value) {
            switch (value) {
              case 'Tools':
                setState(() => typeFilter = 'Tool');
                break;
              case 'Leisure':
                setState(() => typeFilter = 'Leisure');
                break;
              case 'Household':
                setState(() => typeFilter = 'Home');
                break;
              case 'Equipment':
                setState(() => typeFilter = 'Equipment');
                break;
              case 'Miscellaneous':
                setState(() => typeFilter = 'Other');
                break;
              case 'All':
                setState(() => typeFilter = 'All');
                break;
            }
          },
          items: [
            'All',
            'Tools',
            'Leisure',
            'Household',
            'Equipment',
            'Miscellaneous',
          ]
              .map(
                (selection) => DropdownMenuItem<String>(
                  value: selection,
                  child: Text(
                    selection,
                    style: TextStyle(fontFamily: font),
                  ),
                ),
              )
              .toList()),
    );
  }

  Widget conditionSelector() {
    String hint = 'Condition: $conditionFilter';
    double padding = 20;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
          isDense: true,
          //isExpanded: true,
          // [todo value]
          hint: Text(
            hint,
            style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
          ),
          onChanged: (value) {
            setState(() {
              conditionFilter = value;
            });
          },
          items: [
            'All',
            'Lightly Used',
            'Good',
            'Fair',
            'Has Character',
          ]
              .map(
                (selection) => DropdownMenuItem<String>(
                  value: selection,
                  child: Text(
                    selection,
                    style: TextStyle(fontFamily: font),
                  ),
                ),
              )
              .toList()),
    );
  }

  Widget distanceSlider() {
    return Row(
      children: <Widget>[
        Text('Within:\n${distanceFilter.toStringAsFixed(1)} mi'),
        Expanded(
          child: Slider(
            min: 0.0,
            max: 10.0,
            divisions: 20,
            onChanged: distanceIsInfinite
                ? null
                : (newValue) {
                    setState(() => distanceFilter = newValue);
                  },
            label: '${distanceFilter.toStringAsFixed(1)} mi',
            value: distanceFilter,
          ),
        ),
      ],
    );
  }

  Widget sortBy() {
    String hint = 'Sort by: $sortByFilter';

    double padding = 20;

    return Padding(
      padding: EdgeInsets.only(left: padding, right: padding),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
            isDense: true,
            isExpanded: true,
            hint: Text(
              hint,
              style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
            ),
            onChanged: (value) {
              setState(() {
                sortByFilter = value;
              });
            },
            items: [
              'Alphabetically',
              'Price low to high',
              'Rating',
              'Distance',
            ]
                .map(
                  (selection) => DropdownMenuItem<String>(
                    value: selection,
                    child: Text(
                      '$selection',
                      style: TextStyle(fontFamily: font),
                    ),
                  ),
                )
                .toList()),
      ),
    );
  }

  Widget buildItemList() {
    int tileRows = MediaQuery.of(context).size.width > 500 ? 3 : 2;

    if (showSuggestions) {
      return Container();
    }

    if (locIsLoading) {
      //return Text('Getting location...');
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      // final value of radius must be kilometers
      double radius = distanceIsInfinite ? 15000 : distanceFilter;
      radius *= 1.609;
      String field = 'location';

      Query query = Firestore.instance
          .collection('items')
          .where('isVisible', isEqualTo: true);

      if (typeFilter != 'All') {
        query = query.where('type', isEqualTo: typeFilter);
      }

      if (conditionFilter != 'All') {
        query = query.where('condition', isEqualTo: conditionFilter);
      }

      Stream stream;

      if (currentLocation == null) {
        stream = query.snapshots();
      } else {
        GeoFirePoint center = geo.point(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude);

        stream = geo.collection(collectionRef: query).within(
            center: center, radius: radius, field: field, strictMode: true);
      }

      return Expanded(
        child: StreamBuilder(
          stream: stream,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasError) {
              return new Text('${snapshot.error}');
            }
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:

              default:
                if (snapshot.hasData) {
                  List<DocumentSnapshot> items = currentLocation == null
                      ? snapshot.data.documents
                      : snapshot.data;
                  List<Widget> displayCards = [];

                  switch (sortByFilter) {
                    case 'Alphabetically':
                      items.sort((a, b) => a['name']
                          .toLowerCase()
                          .compareTo(b['name'].toLowerCase()));
                      break;
                    case 'Price low to high':
                      items.sort((a, b) => a['price'].compareTo(b['price']));
                      break;
                    case 'Rating':
                      items.sort((a, b) =>
                          (b['rating'].toDouble() / b['numRatings']).compareTo(
                              (a['rating'].toDouble() / a['numRatings'])));
                      break;
                    case 'Distance':
                      break;
                  }

                  for (final ds in items) {
                    double price = ds['price'].toDouble();

                    if (!isAuthenticated ||
                        ds['creator'].documentID != myUserID) {
                      if (searchController.text.isEmpty) {
                        displayCards.add(searchTile(ds, currentUser, context));
                      } else {
                        String name = ds['name'].toLowerCase();
                        String description = ds['description'].toLowerCase();
                        String searchText =
                            searchController.text.trim().toLowerCase();
                        List<String> searchTextList = searchText.split(' ');

                        List<String> itemNameAndDescription = List();
                        itemNameAndDescription.addAll(name.split(' '));
                        itemNameAndDescription.addAll(description.split(' '));

                        bool add = false;

                        for (final searchWord in searchTextList) {
                          RegExp regExp = RegExp(r'^' + searchWord + r'.*$');

                          for (final itemPrefix in itemNameAndDescription) {
                            if (regExp.hasMatch(itemPrefix)) {
                              add = true;
                              break;
                            }
                          }
                        }

                        if (add) {
                          displayCards
                              .add(searchTile(ds, currentUser, context));
                        }
                      }
                    }
                  }

                  return displayCards.isNotEmpty
                      ? ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(20.0),
                          children: displayCards,
                        )
                      : Center(
                          child: Text('No results'),
                        );
                } else {
                  return Container();
                }
            }
          },
        ),
      );
    }
  }

  Future<bool> showUserLocationError() async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                'Problem with getting your current location',
                style: dialogTextStyle,
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void goBack() {
    Navigator.pop(context);
  }
}
