

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:fluttershare/pages/home.dart';

final userRef = Firestore.instance.collection('users'); 

class TimeLine extends StatefulWidget {
  final User currentUser;

  TimeLine({this.currentUser});

  @override
  _TimeLineState createState() => _TimeLineState();
}


class _TimeLineState extends State<TimeLine> {
  List<Post> posts = [];
  @override
  void initState() { 
    super.initState();
    getTimeLine();
  }

  getTimeLine( ) async {
    QuerySnapshot snapshot = await timelineRef
      .document(widget.currentUser.id)
      .collection('timelinePosts')
      .orderBy("timestamp" , descending: true)
      .getDocuments();

      List<Post> posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();

      setState(() {
        this.posts = posts;
      });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if(posts.isEmpty){
      return Text("no Post to show ");
    }
    return ListView(children: posts);
  }


  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,isTitle: true,titleHead: ""),
      body: RefreshIndicator(
        onRefresh: () => getTimeLine(),
        child: buildTimeline(),

      ),
    );
  }
}
