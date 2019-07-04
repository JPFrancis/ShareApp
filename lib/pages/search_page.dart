import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_range_slider/flutter_range_slider.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/services/const.dart';

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
  Geoflutterfire geo = Geoflutterfire();
  Position currentLocation;

  TextEditingController searchController = TextEditingController();
  bool showSuggestions = false;
  List<String> recommendedItems = [];
  List<DocumentSnapshot> prefixSnaps = [];
  List<String> prefixList = [];
  List<String> suggestions = [];

  String myUserID;
  String typeFilter;
  String conditionFilter;
  double minPrice;
  double maxPrice;
  double rangeFilter;
  String sortByFilter;

  bool distanceIsInfinite = true;
  bool pageIsLoading = true;
  bool locIsLoading = false;
  bool isAuthenticated;

  String font = 'Quicksand';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    typeFilter = widget.typeFilter;
    conditionFilter = 'All';
    minPrice = 0.0;
    maxPrice = 50.0;
    rangeFilter = 30.0;
    sortByFilter = 'Alphabetically';

    getMyUserID();
    getSuggestions();
    getUserLocation();
    delayPage();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void delayPage() async {
    Future.delayed(Duration(milliseconds: 750)).then((_) {
      setState(() {
        pageIsLoading = false;
      });
    });
  }

  void getMyUserID() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();

    if (user != null) {
      isAuthenticated = true;
      myUserID = user.uid;
    } else {
      isAuthenticated = false;
    }
  }

  getUserLocation() async {
    setState(() {
      locIsLoading = true;
    });
    GeolocationStatus geolocationStatus =
        await Geolocator().checkGeolocationPermissionStatus();

    if (geolocationStatus != null) {
      if (geolocationStatus != GeolocationStatus.granted) {
        setState(() {
          locIsLoading = false;
        });

        showUserLocationError();
      } else {
        currentLocation = await locateUser();

        if (currentLocation != null) {
          setState(() {
            locIsLoading = false;
          });
        }
      }
    }
  }

  Future<Position> locateUser() async {
    return Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
      minPrice = 0.0;
      maxPrice = 50.0;
      rangeFilter = 30.0;
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
    return WillPopScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 20,
          ),
          searchField(),
          showSuggestions
              ? Container(
                  height: 300,
                  child: buildSuggestionsList(),
                )
              : Container(),
          Container(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              typeSelector(),
              conditionSelector(),
            ],
          ),
          Container(height: 5),
          priceSelector(),
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
                  Text('None'),
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
          buildItemList(),
        ],
      ),
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
              Icons.arrow_back,
              color: primaryColor,
            )),
        Expanded(
          child: searchBox(),
        ),
        IconButton(
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
            height: 50,
            decoration: new BoxDecoration(
              border: Border(left: BorderSide(color: primaryColor, width: 3)),
            ),
            child: Center(
              child: TextField(
                autofocus: widget.showSearch,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontFamily: 'Quicksand', fontSize: 21),
                keyboardType: TextInputType.text,
                controller: searchController,
                onTap: () {
                  setState(() {
                    showSuggestions = true;
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
            title: Text(builderList[index]),
            trailing: IconButton(
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
            ),
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

  Widget priceSelector() {
    double padding = 20;

    return Padding(
      padding: EdgeInsets.only(left: padding, right: padding),
      child: Row(
        children: <Widget>[
          Text('\$ ${minPrice.toStringAsFixed(0)}'),
          Expanded(
            child: RangeSlider(
              min: 0.0,
              max: 100.0,
              lowerValue: minPrice,
              upperValue: maxPrice,
              divisions: 20,
              showValueIndicator: true,
              valueIndicatorFormatter: (int index, double value) {
                String twoDecimals = value.toStringAsFixed(0);
                return '\$ $twoDecimals';
              },
              onChanged: (double newLowerValue, double newUpperValue) {
                setState(() {
                  minPrice = newLowerValue;
                  maxPrice = newUpperValue;
                });
              },
            ),
          ),
          Text('\$ ${maxPrice.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget distanceSlider() {
    return Row(
      children: <Widget>[
        Text('Within:\n${rangeFilter.toStringAsFixed(0)} mi'),
        Expanded(
          child: Slider(
            min: 0.0,
            max: 80.0,
            divisions: 16,
            onChanged: distanceIsInfinite
                ? null
                : (newValue) {
                    setState(() => rangeFilter = newValue);
                  },
            label: '${rangeFilter.toStringAsFixed(0)} mi',
            value: rangeFilter,
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

    if (locIsLoading) {
      //return Text('Getting location...');
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      // final value of radius must be kilometers
      double radius = distanceIsInfinite ? 15000 : rangeFilter;
      radius *= 1.609;
      String field = 'location';

      Query query = Firestore.instance.collection('items');

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

        stream = geo
            .collection(collectionRef: query)
            .within(center: center, radius: radius, field: field);
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
                      items.sort((a, b) => b['rating'].compareTo(a['rating']));
                      break;
                    case 'Distance':
                      break;
                  }

                  for (final ds in items) {
                    double price = ds['price'].toDouble();

                    if ((minPrice <= price && price <= maxPrice) &&
                        (!isAuthenticated ||
                            ds['creator'].documentID != myUserID)) {
                      if (searchController.text.isEmpty) {
                        displayCards.add(searchTile(ds, context));
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
                          displayCards.add(searchTile(ds, context));
                        }
                      }
                    }
                  }

                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20.0),
                    children: displayCards,
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