import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/services/const.dart';

// Reusable Classes

class CustomBoxShadow extends BoxShadow {
  final BlurStyle blurStyle;

  const CustomBoxShadow({
    Color color = const Color(0xFF000000),
    Offset offset = Offset.zero,
    double blurRadius = 0.0,
    this.blurStyle = BlurStyle.normal,
  }) : super(color: color, offset: offset, blurRadius: blurRadius);

  @override
  Paint toPaint() {
    final Paint result = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(this.blurStyle, blurSigma);
    assert(() {
      if (debugDisableShadows) result.maskFilter = null;
      return true;
    }());
    return result;
  }
}

class StarRating extends StatelessWidget {
  final int starCount;
  final double rating;
  final Color color;
  final double sz;

  StarRating({this.starCount = 5, this.rating = .0, this.color, this.sz});

  Widget buildStar(BuildContext context, int index, h) {
    Icon icon;
    if (index >= rating) {
      icon = new Icon(
        Icons.star_border,
        color: primaryColor,
        size: sz,
      );
    } else if (index > rating - 1 && index < rating) {
      icon = new Icon(
        Icons.star_half,
        color: primaryColor,
        size: sz,
      );
    } else {
      icon = new Icon(
        Icons.star,
        color: primaryColor,
        size: sz,
      );
    }
    return icon;
  }

  Widget build(BuildContext context) {
    return new Row(
        children: new List.generate(
            starCount, (index) => buildStar(context, index, sz)));
  }
}
// Reusable Widgets

Widget itemCard(DocumentSnapshot ds, context) {
  CachedNetworkImage image = CachedNetworkImage(
    imageUrl: ds['images'][0],
    placeholder: (context, url) => new CircularProgressIndicator(),
  );

  var card = new Container(child: new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
    double h = constraints.maxHeight;
    double w = constraints.maxWidth;
    return Container(
      height: h,
      width: w,
      decoration: new BoxDecoration(
        boxShadow: <BoxShadow>[
          CustomBoxShadow(
              color: Colors.black45,
              blurRadius: 4.0,
              blurStyle: BlurStyle.outer),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Container(
            height: h,
            width: w,
            child: FittedBox(
              fit: BoxFit.cover,
              child: image,
            ),
          ),
          /*
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(ds['images'][0]),
                fit: BoxFit.cover,
              ),
            ),
          ),
          */
          SizedBox.expand(
            child: Container(
              color: Colors.black12,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: h / 3.5,
              width: w,
              padding: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  CustomBoxShadow(
                      color: Colors.black38,
                      blurRadius: 0.1,
                      blurStyle: BlurStyle.outer),
                ],
                color: Color.fromARGB(220, 255, 255, 255),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 5.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(ds['name'],
                          style: TextStyle(
                              fontSize: h / 20,
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.bold)),
                      Text(
                        '${ds['type']}'.toUpperCase(),
                        style: TextStyle(
                            fontSize: h / 25,
                            fontFamily: 'Quicksand',
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 2.0,
                  ),
                  Text("\$${ds['price']} per day",
                      style: TextStyle(
                          fontSize: h / 21,
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w400)),
                  SizedBox(
                    height: 2.0,
                  ),
                  Row(
                    children: <Widget>[
                      StarRating(rating: ds['rating'].toDouble(), sz: h / 15),
                      SizedBox(width: 5.0),
                      Text(
                        ds['numRatings'].toString(),
                        style: TextStyle(
                            fontSize: h / 23,
                            fontFamily: 'Quicksand',
                            fontWeight: FontWeight.w400),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }));

  return InkWell(
      onTap: () {
        navigateToDetail(ds, context);
      },
      child: card);
}

Widget reusableCategory(text) {
  return Container(
      padding: EdgeInsets.only(left: 15.0, top: 10.0),
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w100)));
}

Widget reusableCategoryWithAll(text, action) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Container(
          padding: EdgeInsets.only(left: 15.0),
          child: Text(text,
              style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Quicksand'))),
      Container(
          child: FlatButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        child: Text(
          "View All",
          style: TextStyle(
              fontSize: 12.0,
              fontFamily: 'Quicksand',
              color: primaryColor,
              fontWeight: FontWeight.w400),
        ),
        onPressed: action,
      )),
    ],
  );
}

Widget reusableFlatButton(text, icon, action) {
  return Column(
    children: <Widget>[
      Container(
        child: FlatButton(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(text, style: TextStyle(fontFamily: 'Quicksand')),
              Icon(icon)
            ],
          ),
          onPressed: () => action(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(
          left: 15.0,
          right: 15.0,
        ),
        child: Divider(),
      )
    ],
  );
}

Widget divider() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Divider(),
  );
}

Widget backButton(context) {
  return IconButton(
    alignment: Alignment.topLeft,
    icon: BackButton(),
    onPressed: () => Navigator.pop(context),
  );
}

// helper methods

void navigateToDetail(DocumentSnapshot itemDS, context) async {
  Navigator.pushNamed(
    context,
    ItemDetail.routeName,
    arguments: ItemDetailArgs(
      itemDS,
    ),
  );
}

void delayPage() async {
  await Future.delayed(Duration(milliseconds: 500));
}
