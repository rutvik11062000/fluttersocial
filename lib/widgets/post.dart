import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String medialUrl;
  final dynamic like;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.medialUrl,
    this.like,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      medialUrl: doc['medialUrl'],
      like: doc['like'],
    );
  }

  int getLikeCount(like) {
    if (like == null) {
      return 0;
    }
    int count = 0;
    like.values.forEach((val) {
      if (val == true) {
        count = count + 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        medialUrl: this.medialUrl,
        like: this.like,
        likeCount: getLikeCount(this.like),
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String medialUrl;
  Map like;
  int likeCount;
  bool isLiked;
  bool showHeart = false;

  _PostState(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.description,
      this.medialUrl,
      this.like,
      this.likeCount});

  buildPostHeader() {
    return FutureBuilder(
      future: userRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: ownerId),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner ? IconButton(
            onPressed: () => handleDeletePost(context),
            icon: Icon(Icons.more_vert),
          ):Text(""),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this Post ? "),
            children: <Widget>[
              SimpleDialogOption(
                child: Text(
                  "Delete Post",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
              ),
              SimpleDialogOption(
                child: Text(
                  "cancel",
                  
                ),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  deletePost() async{
      postRef
        .document(ownerId)
        .collection('userPost')
        .document(postId)
        .get().then((doc) {
           if (doc.exists){
             doc.reference.delete();
           }
        });

      storageRef
        .child("post_$postId.jpg").delete();

    QuerySnapshot activityFeedSnapshot = await activityFeedRef
      .document(ownerId)
      .collection("feedItems")
      .where('postId', isEqualTo : postId)
      .getDocuments();
      

      activityFeedSnapshot.documents.forEach((doc) {
          if (doc.exists) {
            doc.reference.delete();
          }
      });

      QuerySnapshot commentsSnapshot = await commentsRef
      .document(postId)
      .collection("comments")
      .getDocuments();
      

      commentsSnapshot.documents.forEach((doc) {
          if (doc.exists) {
            doc.reference.delete();
          }
      });
      
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Image.network(medialUrl),
          CachedNetworkImage(imageUrl: medialUrl),
          showHeart
              ? Animator(
                  tween: Tween(begin: 0.8, end: 1.4),
                  duration: Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (anim) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 80.0,
                      color: Colors.white70,
                    ),
                  ),
                )
              : Text(""),
        ],
      ),
    );
  }

  handleLikePost() {
    bool _isLiked = like[currentUserId] == true;

    if (_isLiked) {
      postRef
          .document(ownerId)
          .collection('userPost')
          .document(postId)
          .updateData({'like.$currentUserId': false});

      removeLikeFromFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        like[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postRef
          .document(ownerId)
          .collection('userPost')
          .document(postId)
          .updateData({'like.$currentUserId': true});

      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        like[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    bool isnotOwner = currentUserId != ownerId;
    if (isnotOwner) {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .setData({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImage": currentUser.photoUrl,
        "postId": postId,
        "medialUrl": medialUrl,
        "timestamp": timestamp,
      });
    }
  }

  removeLikeFromFeed() {
    activityFeedRef
        .document(ownerId)
        .collection("feedItems")
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 40.0, left: 20.0),
            ),
            GestureDetector(
              child: IconButton(
                onPressed: handleLikePost,
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: Colors.pink,
                  size: 30.0,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 5.0),
            ),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                medialUrl: medialUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "$username",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              width: 10.0,
            ),
            Expanded(child: Text(description)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (like[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}

showComments(BuildContext context,
    {String postId, String ownerId, String medialUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMedialUrl: medialUrl,
    );
  }));
}
