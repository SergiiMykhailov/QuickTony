const functions = require('firebase-functions');
const admin = require('firebase-admin');
const gcs = require('@google-cloud/storage')();

admin.initializeApp(functions.config().firebase);

// exports.addMessage = functions.https.onRequest((req, res) => {
//   const userId = req.query.user;
//   const usersVisheoPath = '/users/'+userId+'/cards'
//   admin.database().ref(usersVisheoPath).once('value',snapshot => {
//     let userVisheos = snapshot.val()
//     snapshot.forEach(function(child) {
//       var defaultStorage = admin.storage().bucket();
//
//       const visheoId = child.key
//       const bucket = gcs.bucket('visheo42.appspot.com');
//
//       const premiumPath = 'PremiumVisheos/' + visheoId;
//       const premiumFile = bucket.file(premiumPath);
//
//       const freePath = 'FreeVisheos/' + visheoId;
//       const freeFile = bucket.file(freePath);
//
//       const pr = premiumFile.delete();
//       const pr_f = freeFile.delete();
//
//       console.log(visheoId)
//       admin.database().ref('/cards/').child(visheoId).remove();
//     });
//     admin.database().ref('/users/').child(userId).remove()
//
//     res.redirect(303, snapshot.ref);
//   });
// });

exports.userDidDeleted = functions.auth.user().onDelete(event => {
  const user = event.data;
  const userId = user.uid;
  const usersVisheoPath = '/users/'+userId+'/cards'
  admin.database().ref(usersVisheoPath).once('value',snapshot => {
    let userVisheos = snapshot.val()
    snapshot.forEach(function(child) {
      var defaultStorage = admin.storage().bucket();

      const visheoId = child.key
      const bucket = gcs.bucket('visheo42.appspot.com');

      const premiumPath = 'PremiumVisheos/' + visheoId;
      const premiumFile = bucket.file(premiumPath);

      const freePath = 'FreeVisheos/' + visheoId;
      const freeFile = bucket.file(freePath);

      const pr = premiumFile.delete();
      const pr_f = freeFile.delete();

      admin.database().ref('/cards/').child(visheoId).remove();
    });
    admin.database().ref('/users/').child(userId).remove()
  });
});
