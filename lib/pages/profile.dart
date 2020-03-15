

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {
  String profileID;
  Profile({this.profileID});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isFollowing = false;
  bool isloading = false;
  int postCount = 0;
  int countFollowers = 0;
  int countFollowing = 0;
  
  List<Post> posts = [];
  String postOrientation = "grid";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getProfilePost();
    getFollowers();
    getFollowing();
    checkIfFollow();
  }

  checkIfFollow() async{
    DocumentSnapshot doc =  await followersRef.document(widget.profileID).collection('userFollowers').document(currentUserId).get();

    setState(() {
      isFollowing = doc.exists;
    });

  }

  getFollowers() async{
    QuerySnapshot snapshot = await followersRef.document(widget.profileID).collection('userFollowers').getDocuments();
    setState(() {
      countFollowers = snapshot.documents.length;
    });
  }

  getFollowing() async{
    QuerySnapshot snapshot = await followingRef.document(widget.profileID).collection('userFollowing').getDocuments();
    setState(() {
      countFollowing = snapshot.documents.length;
    });

  }


  getProfilePost() async{
      setState(() {
        isloading = true; 

      });
        QuerySnapshot snapshot = await postRef.document(widget.profileID)
        .collection('userPost')
        .orderBy('timestamp', descending: true)
        .getDocuments();
        setState(() {
          isloading = false;
          postCount = snapshot.documents.length;
          posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
        });
  }


  final currentUserid = currentUser?.id;

  Column buildRowWidget(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w400,
              fontSize: 15.0,
            ),
          ),
        )
      ],
    );
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: userRef.document(widget.profileID).get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildRowWidget("post", postCount),
                            buildRowWidget("Followers", countFollowers),
                            buildRowWidget("Following", countFollowing),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfoleButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.only(top: 12.0),
                alignment: Alignment.centerLeft,
                child: Text(user.username,
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: EdgeInsets.only(top: 4.0),
                alignment: Alignment.centerLeft,
                child: Text(user.email,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: EdgeInsets.only(top: 2.0),
                alignment: Alignment.centerLeft,
                child: Text(user.bio),
              ),
            ],
          ),
        );
      },
    );
  }

  Container buildButton({String label, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 240.0,
          height: 27.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue,
            border: Border.all(
              color: Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  buildProfoleButton() {
    bool isOwner = currentUserid == widget.profileID;
    if (isOwner) {
      return buildButton(label: "edit profile", function: editUserProfile);
    }else if(isFollowing){
      return buildButton(label: "Unfollow", function: handleUnFollowingUser);
    }else if(!isFollowing){
      return buildButton(label: "Follow", function: handleFollowingUser);
    }
  }

  handleUnFollowingUser(){
      setState(() {
        isFollowing = false;

      });
      followersRef
        .document(widget.profileID)
        .collection('userFollowers')
        .document(currentUserId)
        .get().then((doc){
          if(doc.exists){
            doc.reference.delete();
          }
        });

      followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileID)
        .get().then((doc){
          if(doc.exists){
            doc.reference.delete();
          }
        });

      activityFeedRef
        .document(widget.profileID)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
          "type" : "follow",
          "ownerId" : widget.profileID,
          "username" : currentUser.username,
          "userId" : currentUserId,
          "userProfileImage" : currentUser.photoUrl,
          "timestamp" : timestamp,
        });
  }


  handleFollowingUser(){
      setState(() {
        isFollowing = true;

      });
      followersRef
        .document(widget.profileID)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({});

      followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileID)
        .setData({});

      activityFeedRef
        .document(widget.profileID)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
          "type" : "follow",
          "ownerId" : widget.profileID,
          "username" : currentUser.username,
          "userId" : currentUserId,
          "userProfileImage" : currentUser.photoUrl,
          "timestamp" : timestamp,
        });
  }

  editUserProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile(currenUserID : currentUserid)));
  }
  // buildProfilePost(){
  //     if(isloading){
  //       return circularProgress();
  //     }
  //     return Column(children: posts,);
  // }

  buildProfilePost() {
    if (isloading) {
      return circularProgress();
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    }
  }



  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setPostOrientation("grid"),
          icon: Icon(Icons.grid_on),
          color: postOrientation == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          onPressed: () => setPostOrientation("list"),
          icon: Icon(Icons.list),
          color: postOrientation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleHead: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(height : 0.0),
          buildProfilePost(),
        ],
      ),
    );
  }
}
