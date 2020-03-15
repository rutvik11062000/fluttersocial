import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController captionCOntroller  = TextEditingController();
  TextEditingController locationController = TextEditingController();
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();

  takeFromCamera() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      this.file = file;
    });
  }

  chooseFromgallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
    });
  }

  selectimage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Create post"),
            children: <Widget>[
              SimpleDialogOption(
                child: Text("Take photo with camera"),
                onPressed: () => takeFromCamera(),
              ),
              SimpleDialogOption(
                child: Text("Choose from gallery"),
                onPressed: () => chooseFromgallery(),
              ),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: 260,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
              onPressed: () => selectimage(context),
              child: Text(
                "Choose Photo",
                style: TextStyle(color: Colors.white, fontSize: 20.0),
              ),
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }
  
  compressImage() async{
    final tempoDir = await getTemporaryDirectory();
    final path  = tempoDir.path;
    Im.Image  imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
    ..writeAsBytesSync(Im.encodeJpg(imageFile,quality: 70));

    setState(() {
      file = compressedImageFile;
    });

  }

  Future<String> uploadImage(imageFile) async{
     StorageUploadTask uploadTask =  storageRef.child("post_$postId.jpg").putFile(imageFile);
     StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
     String downloadUrl = await storageSnap.ref.getDownloadURL();
     return downloadUrl;
  }

  createPostInFirestore({ String mediaUrl , String location, String description}){
    postRef.document(widget.currentUser.id)
    .collection("userPost")
    .document(postId)
    .setData({
       "postId" : postId,
       "ownerId" : widget.currentUser.id,
       "username" : widget.currentUser.username,
       "medialUrl" : mediaUrl,
       "description" : description,
       "location" : location,
       "like" : {},
       "timestamp" : timestamp,
    }); 
    captionCOntroller.clear();
    locationController.clear();
    setState(() {
      isUploading = false;
      file = null;
      postId = Uuid().v4();

    });

  }

  handleSubmit() async{
    setState(() {
      isUploading  = true;
    });
    await compressImage();
    String mediaUrl =  await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionCOntroller.text,
    );
  }


  Scaffold buildUpload() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: clearImage,
        ),
        title: Text(
          "Create Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
              child: Text(
            "Post",
            style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0),
          ))
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.cover, image: FileImage(file)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionCOntroller,
                decoration: InputDecoration(
                  hintText: "Write A Caption",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              onPressed: () => getCurrwntLocation(),
              icon: Icon(Icons.my_location,color: Colors.white,),
              label: Text("Current Location",style: TextStyle(color: Colors.white),),
              color: Colors.blue,
              
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
  getCurrwntLocation() async{
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String formattedLocation = '${placemark.locality},${placemark.country}';
    locationController.text = formattedLocation;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUpload();
  }
}
