const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
exports.onCreateFollower = functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onCreate(async (snapshot, context) => {
    console.log("Follower Created", snapshot.id);
    const userId = context.params.userId;
    const followerId = context.params.followerId;

    // 1) Create followed users posts ref
    const followedUserPostsRef = admin
      .firestore()
      .collection("post")
      .doc(userId)
      .collection("userPost");

    // 2) Create following user's timeline ref
    const timelinePostsRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePosts");

    // 3) Get followed users posts
    const querySnapshot = await followedUserPostsRef.get();

    // 4) Add each user post to following user's timeline
    querySnapshot.forEach(doc => {
      if (doc.exists) {
        const postId = doc.id;
        const postData = doc.data();
        timelinePostsRef.doc(postId).set(postData);
      }
    });
  });

exports.onDeleteFollower = functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onDelete(async (snapshot, context) => {
    console.log("Follower Deleted", snapshot.id);

    const userId = context.params.userId;
    const followerId = context.params.followerId;

    const timelinePostsRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePosts")
      .where("ownerId", "==", userId);

    const querySnapshot = await timelinePostsRef.get();
    querySnapshot.forEach(doc => {
      if (doc.exists) {
        doc.ref.delete();
      }
    });
  });

exports.onCreatePost = functions.firestore
  .document("/post/{userId}/userPost/{postId}")
  .onCreate(async (snapshot, context) => {
    const postCreated = snapshot.data();
    const userId = ocntext.params.userId;
    const postId = context.params.postId;

    const userFollowers = admin.firestore()
      .collection('followers')
      .doc(userId)
      .collection('userFollowers');

    const querySnapshot = await userFollowers.get();

    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection('timeline')
        .doc(postId)
        .collection('timelineposts')
        .doc(postId)
        .set(postCreated);

    });
  });

exports.onCreatePost = functions.firestore
  .document("/post/{userId}/userPost/{postId}")
  .onUpdate(async (change, context) => {
    const postUpdated = change.after.data();
    const userId = ocntext.params.userId;
    const postId = context.params.postId;

    const userFollowers = admin.firestore()
      .collection('followers')
      .doc(userId)
      .collection('userFollowers');

    const querySnapshot = await userFollowers.get();
    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection('timeline')
        .doc(postId)
        .collection('timelineposts')
        .doc(postId)
        .get().then(doc => {
          if (doc.exists) {
            doc.ref.update(postUpdated);
          }
        });

    });


  });


exports.onDeletePost = functions.firestore
  .document("/post/{userId}/userPost/{postId}")
  .onDelete(async (snapshot, context) => {
    const userId = ocntext.params.userId;
    const postId = context.params.postId;

    const userFollowers = admin.firestore()
      .collection('followers')
      .doc(userId)
      .collection('userFollowers');

    const querySnapshot = await userFollowers.get();
    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection('timeline')
        .doc(postId)
        .collection('timelineposts')
        .doc(postId)
        .get().then(doc => {
          if (doc.exists) {
            doc.ref.delete;
          }
        });

    });
  });


exports.onCreateActivityFeedItem = functions.firestore
  .document('/feed/{userId}/feedItems/{activityFeedItem}')
  .onCreate(async (snapshot, context) => {
    console.log('Activity Feed Item Created', snapshot.data());

    const userId = context.params.userId;
    const userRef = admin.firestore().doc(`user/${userId}`);
    const doc = await userRef.get();

    const androidNotificationToken = doc.data().androidNotificationToken;

    if (androidNotificationToken) {
        sendNotification(androidNotificationToken, snapshot.data());
    } else {
      console.log("no token for the user");
    }

    function sendNotification(androidNotificationToken, activityFeedItem) {
      let body;

      switch (activityFeedItem.type) {
        case "comments":
          body = `${activityFeedItem.username} replied: ${activityFeedItem.commentData} `;
          break;

        case "like":
          body = `${activityFeedItem.username} liked your post `;
          break;

        case "follow":
          body = `${activityFeedItem.username} started following you `;
          break;

        default:
          break;
      }

      const message = {
        notification : {body},
        token: androidNotificationToken,
        data: {recipient: userId }
      };

      admin
        .messaging()
        .send(message)
        .then(response => { console.log("successfully sent message", response);})
        .catch(error => {
              console.log("sendning error" , error);
        })
    }

  });