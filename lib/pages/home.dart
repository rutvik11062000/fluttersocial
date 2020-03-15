import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';


final GoogleSignIn googleSignIn = new GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final userRef = Firestore.instance.collection('user');
final postRef = Firestore.instance.collection('post');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followingRef = Firestore.instance.collection('following');
final followersRef = Firestore.instance.collection('followers');
final timelineRef = Firestore.instance.collection('timeline');
final timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); 
 FirebaseMessaging  _firebaseMessaging = FirebaseMessaging();
bool isauth = false;
PageController pageController;
int pageIndex = 0; 




@override
void initState() { 
  super.initState();
  pageController = PageController();
  googleSignIn.onCurrentUserChanged.listen((account){
    handleSignIn(account);
  }, onError: (err){
      print('Error signing in : $err');
  });
  // reauthenticate user when app is reopened

  googleSignIn.signInSilently(suppressErrors: false)
  .then((account){
    handleSignIn(account);
  }).catchError((err){
     print('Error signing in : $err');
  });

}

handleSignIn(account) async{
if (account != null) {
       await createUserAccount();
      setState(() {
        isauth = true;
      }); 
      configurePushNotificaitons();
    } else {
      setState(() {
        isauth = false;
      });
    }
}

configurePushNotificaitons(){
      final GoogleSignInAccount user = googleSignIn.currentUser;
      if (Platform.isIOS) getiOSPermission();
      _firebaseMessaging.getToken().then((token) {
        print("firebase mesaging token: $token\n");
        userRef
        .document(user.id)
        .updateData({"androidNotificationToken" : token});
      });

       _firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          print("Notification shown!");
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print("Notification NOT shown");
      },
    );
}

getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered: $settings");
    });
  }

createUserAccount() async{
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await userRef.document(user.id).get();

    if (!doc.exists) {
    
      final username = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAccount(),),);
      userRef.document(user.id).setData({
        "id" : user.id,
        "username": username,
        "photoUrl" : user.photoUrl,
        "email" : user.email,
        "displayName" : user.displayName,
        "bio" : "",
        "timestamp" : timestamp,
        });
        doc = await userRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
    print(currentUser);
    print(currentUser.username);

}


login(){
  googleSignIn.signIn();
}

logout(){
  googleSignIn.signOut();
}

@override
void dispose() { 
  pageController.dispose();
  super.dispose();
}

onPageChanged(int pageIndex){
  setState(() {
    this.pageIndex = pageIndex;
  });
}

onTap(int pageIndex){
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut
      );
}


  Scaffold buildAuthScreen() {
    return Scaffold(
      key : _scaffoldKey,
      body: PageView(
        children: <Widget>[
         
          TimeLine(currentUser : currentUser),
          ActivityFeed(),
          Upload(currentUser : currentUser),
          Search(),
          Profile(profileID : currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera,size: 35.0,), ),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor,
              
            ]  
          ),
        ),
        alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center ,
        children: <Widget>[
          Text(
            'FlutterShare',
            style: TextStyle(
              fontFamily: "Signatra",
              fontSize: 90.0,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: login,
            child: Container(
              width: 260.0,
              height: 60.0,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/google_signin_button.png',),
                  
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return isauth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
