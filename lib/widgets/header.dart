import 'package:flutter/material.dart';

AppBar header(context, {bool isTitle = false, String titleHead, removebackbutton = false}) {
  return AppBar(
    automaticallyImplyLeading: removebackbutton ? false : true,
    title: Text( isTitle ? "FlutterShare" : titleHead,
     style: TextStyle(
     fontFamily: isTitle ? "Signatra" : "",
      color: Colors.white,
      fontSize: isTitle? 50.0: 30.0,
 
    ),
    ),
    backgroundColor: Theme.of(context).accentColor,
    centerTitle: true,
  );
}
