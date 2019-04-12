import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';

final homeScaffoldKey = GlobalKey<ScaffoldState>();

GoogleMapsPlaces _places;

class SelectLocation extends StatefulWidget {
  static const routeName = '/selectLocation';
  GeoPoint geoPoint;

  SelectLocation(this.geoPoint);

  @override
  State<StatefulWidget> createState() {
    return SelectLocationState(this.geoPoint);
  }
}

class SelectLocationState extends State<SelectLocation> {
  GeoPoint geoPoint;

  String kGoogleApiKey;


  StreamSubscription<Position> dataSub;
  GoogleMapController _controller;
  LatLng center = LatLng(39.08, -76.98);

  Position position;

  bool isLoading = false;
  String error;
  double zoom = 15.0;

  Map<MarkerId, Marker> markerSet = <MarkerId, Marker>{};
  bool hasMarker = false;
  MarkerId selectedMarker;
  String markerName = 'Your Selected Location';
  LatLng markerLatLng;

  CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(39.08, -76.98),
    zoom: 9.7,
  );

  SelectLocationState(this.geoPoint);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getKey();

    if (geoPoint != null) {
      double lat = geoPoint.latitude;
      double long = geoPoint.longitude;

      setState(() {
        hasMarker = true;
        position = Position(latitude: lat, longitude: long);
        initialCameraPosition = CameraPosition(
          target: LatLng(lat, long),
          zoom: zoom,
        );
      });

      addMarker(lat, long);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: homeScaffoldKey,
      appBar: AppBar(
        title: Text('Select location'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, geoPoint);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              showHelp();
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Stack(
            children: <Widget>[
              GoogleMap(
                mapType: MapType.normal,
                rotateGesturesEnabled: false,
                initialCameraPosition: initialCameraPosition,
                onMapCreated: (GoogleMapController controller) {
                  _controller = controller;
                },
                markers: Set<Marker>.of(markerSet.values),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: ButtonTheme(
                  minWidth: double.infinity,
                  height: 40.0,
                  child: RaisedButton(
                    color: Colors.grey[300],
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(7.0)),
                    onPressed: _handlePressButton,
                    child: Text(
                      "Search",
                      textScaleFactor: 1.4,
                    ),
                  ),
                ),
              ),
              showCircularProgress(),
            ],
          )
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 55.0),
        child: FloatingActionButton(
          onPressed: goToCurrLoc,
          child: Icon(Icons.my_location),
          tooltip: 'Get current location',
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  height: 60,
                  child: FlatButton(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed: reset,
                    child: Text(
                      'Reset',
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 60,
                  child: FlatButton(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed: hasMarker ? done : null,
                    child: Text(
                      'Done',
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void getKey() async {
    String ret = await getKeyH();
    kGoogleApiKey = ret;
    _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
  }

  Future<String> getKeyH() async {
    DocumentSnapshot ds = await Firestore.instance
        .collection('keys')
        .document('maps_key')
        .get();

    return ds['key'];
  }

  reset() {
    setState(() {
      geoPoint = null;
      isLoading = false;
      removeMarker();
      resetCamera();
      dataSub.cancel();
    });
  }

  resetCamera() {
    setCamera(39.08, -76.98, 9.7);
  }

  void done() {
    Navigator.pop(context, geoPoint);
  }

  Widget showCircularProgress() {
    //return isLoading ? Center(child: CircularProgressIndicator()) : Container();
    return isLoading
        ? Container(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Center(child: CircularProgressIndicator()),
                  Container(
                    height: 40.0,
                  ),
                  Text(
                    "Getting current location ...\n"
                        "Press \'Reset\' if\nit takes too long",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ]),
          )
        : Container();
  }

  Future<void> goToCurrLoc() async {
    setState(() {
      isLoading = true;
    });

    dataSub = getCurrLoc().asStream().listen((Position p) {
      setState(() {
        isLoading = false;
        position = p;
        addMarker(p.latitude, p.longitude);
      });
    });
/*
    Position waitForLoc = await getCurrLoc();

    if (isLoading && waitForLoc != null) {
      setState(() {
        isLoading = false;
        _position = waitForLoc;
      });
    }
    */
  }

  Future<Position> getCurrLoc() async {
    Position position;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      final Geolocator geolocator = Geolocator()
        ..forceAndroidLocationManager = true;
      position = await geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } on PlatformException {
      position = null;
    }

    //if (mounted)
    return position;
  }

  void setCamera(double lat, double long, double zoom) async {
    LatLng newLoc = LatLng(lat, long);
    //final GoogleMapController controller = await _controller.future;
    _controller.animateCamera(CameraUpdate.newCameraPosition(
        new CameraPosition(target: newLoc, zoom: zoom)));
  }

  addMarker(double lat, double long) {
    if (hasMarker) {
      removeMarker();
    }

    final MarkerId markerID = MarkerId(markerName);

    final Marker marker = Marker(
      markerId: markerID,
      position: LatLng(
        lat,
        long,
      ),
      infoWindow:
          InfoWindow(title: markerName, snippet: LatLng(lat, long).toString()),
      onTap: () {
        onMarkerTapped(markerID);
        //changeInfo();
      },
    );

    setState(() {
      markerSet[markerID] = marker;
      markerLatLng = new LatLng(lat, long);
      hasMarker = true;
      geoPoint = GeoPoint(lat, long);
      setCamera(lat, long, zoom);
    });
  }

  void onMarkerTapped(MarkerId markerId) {
    final Marker tappedMarker = markerSet[markerId];
    if (tappedMarker != null) {
      setState(() {
        if (markerSet.containsKey(selectedMarker)) {
          final Marker resetOld = markerSet[selectedMarker]
              .copyWith(iconParam: BitmapDescriptor.defaultMarker);
          markerSet[selectedMarker] = resetOld;
        }
        selectedMarker = markerId;
        final Marker newMarker = tappedMarker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        );
        markerSet[markerId] = newMarker;
      });
    }
  }

  Future<void> toggleDraggable() async {
    final Marker marker = markerSet[selectedMarker];
    setState(() {
      markerSet[selectedMarker] = marker.copyWith(
        draggableParam: !marker.draggable,
        positionParam: marker.position,
      );
    });
  }

  void removeMarker() {
    setState(() {
      markerSet.clear();
      hasMarker = false;
    });
  }

  Widget showHelp() {
    showDemoDialog<String>(
      context: context,
      child: AlertDialog(
        title: const Text('Help'),
        content: Text(
          'Search for your address or use your current '
              'location. When the marker is placed, '
              'click on it to show navigation button. '
              '\'Reset\' will remove the marker, and '
              'press \'Done\' when you are finished.',
          style: Theme.of(context)
              .textTheme
              .subhead
              .copyWith(color: Theme.of(context).textTheme.caption.color),
        ),
        actions: <Widget>[
          FlatButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void showDemoDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.
    });
  }

  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  Future<void> _handlePressButton() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
      onError: onError,
      mode: Mode.overlay,
      language: "en_US",
      components: [Component(Component.country, "us")],
    );

    //displayPrediction(p, homeScaffoldKey.currentState);

    if (p != null) {
      // get detail (lat/lng)
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;

      addMarker(lat, lng);
    }
  }
}

Future<Null> showSnackBar(String msg, ScaffoldState scaffold) async {
  scaffold.showSnackBar(
    SnackBar(content: Text(msg)),
  );
}

Future<Null> displayPrediction(Prediction p, ScaffoldState scaffold) async {
  if (p != null) {
    // get detail (lat/lng)
    PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId);
    final lat = detail.result.geometry.location.lat;
    final lng = detail.result.geometry.location.lng;

    scaffold.showSnackBar(
      SnackBar(content: Text("${p.description} - $lat/$lng")),
    );
  }
}

class Uuid {
  final Random _random = Random();

  String generateV4() {
    // Generate xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx / 8-4-4-4-12.
    final int special = 8 + _random.nextInt(4);

    return '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-'
        '${_bitsDigits(16, 4)}-'
        '4${_bitsDigits(12, 3)}-'
        '${_printDigits(special, 1)}${_bitsDigits(12, 3)}-'
        '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}';
  }

  String _bitsDigits(int bitCount, int digitCount) =>
      _printDigits(_generateBits(bitCount), digitCount);

  int _generateBits(int bitCount) => _random.nextInt(1 << bitCount);

  String _printDigits(int value, int count) =>
      value.toRadixString(16).padLeft(count, '0');
}
