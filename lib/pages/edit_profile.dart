import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  String currenUserID;
  EditProfile({this.currenUserID});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool isLoading = false;
  User user;
  bool _displayValid = true;
  bool _bioValid = true;
  final _scaffoldKey = GlobalKey<ScaffoldState>();


  TextEditingController bioContrfoller = TextEditingController();
  TextEditingController displaynameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await userRef.document(widget.currenUserID).get();
    user = User.fromDocument(doc);
    displaynameController.text = user.username;
    bioContrfoller.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  buildDisplayForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 60.0),
            child: Text(
              "User Name",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextField(
            controller: displaynameController,
            decoration: InputDecoration(
              hintText: "Display Name",
              errorText: _displayValid ? null : "Display name too short",
            ),
          ),
        ],
      ),
    );
  }
  logout() async{
      await googleSignIn.signOut();
      Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  buildBioForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 30.0),
            child: Text(
              "Bio",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextField(
            controller: bioContrfoller,
            decoration: InputDecoration(
              hintText: "Insert Bio",
              errorText: _bioValid ? null : "Bio Too Long",
            ),
          ),
        ],
      ),
    );
  }
  editUserProfile(){
    setState(() { 
      displaynameController.text.trim().length < 3 || displaynameController.text.isEmpty ? _displayValid = false :  _displayValid = true ;
      bioContrfoller.text.length > 100 ? _bioValid = false : _bioValid = true;
    });

    if (_displayValid && _bioValid) {
      userRef.document(widget.currenUserID).updateData({"displayName" : displaynameController.text, "bio" : bioContrfoller.text});
    }
    SnackBar snackbar = SnackBar(content: Text("Profile Updated"));
    _scaffoldKey.currentState.showSnackBar(snackbar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text(
            "Edit Profile",
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.done,
                color: Colors.green,
                size: 30.0,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: isLoading
            ? circularProgress()
            : ListView(
                children: <Widget>[
                  Container(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                          child: CircleAvatar(
                            radius: 50.0,
                            backgroundColor: Colors.grey,
                            backgroundImage: NetworkImage(user.photoUrl),
                          ),
                        ),
                        buildDisplayForm(),
                        buildBioForm(),
                        RaisedButton(
                        onPressed: editUserProfile,
                        child: Text(
                          "Update Profile",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FlatButton.icon(
                          onPressed: logout,
                          icon: Icon(Icons.cancel, color: Colors.red),
                          label: Text(
                            "Logout",
                            style: TextStyle(color: Colors.red, fontSize: 20.0),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ],
              ));
  }
}
