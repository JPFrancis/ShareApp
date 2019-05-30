const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);

const firestore = admin.firestore();
const settings = { timestampInSnapshots: true };
firestore.settings(settings);

const stripe = require('stripe')(functions.config().stripe.token);

exports.addStripeSource = functions.firestore.document('cards/{userId}/tokens/{tokenId}')
    .onWrite(async (tokenSnap, context) => {
        var customer;
        const data = tokenSnap.after.data();

        if (data === null) {
            return null
        }

        const token = data.tokenId;
        const snapshot = await firestore.collection('cards').doc(context.params.userId).get();
        const customerId = snapshot.data().custId;
        const customerEmail = snapshot.data().email;

        if (customerId === 'new') {
            customer = await stripe.customers.create({
                email: customerEmail,
                source: token
            });

            firestore.collection('cards').doc(context.params.userId).update({
                custId: customer.id
            });
        } else {
            customer = await stripe.customers.retrieve(customerId);
        }

        const customerSource = customer.sources.data[0];

        return firestore.collection('cards').doc(context.params.userId).collection('sources').
            doc(customerSource.card.fingerprint).set(customerSource, {
                merge: true
            });
    })

exports.createUser = functions.auth.user().onCreate(event => {
    console.log('User id to be created: ', event.uid);

    const userID = event.uid;
    const email = event.email;
    const photoURL = event.photoURL || 'https://bit.ly/2vcmALY';
    const name = event.displayName || 'new user';
    const creationDate = Date.now();

    firestore.collection('cards').doc(userID).set({
        custId: 'new',
        email: email,
    }).then(function () {
        console.log('Added card for user ', userID);
        return 'Added card for user $userID';
    }).catch(error => {
        console.error('Error when adding card for new user! ', error);
    });

    return firestore.collection('users').doc(userID).set({
        email: email,
        avatar: photoURL,
        name: name,
        lastActive: Date.now(),
        creationDate: creationDate,
    }).then(function () {
        console.log('Created user: ', userID);
        return 'Created user $userID';
    }).catch(error => {
        console.error('Error when creating user! ', error);
    });
});

exports.deleteUser = functions.auth.user().onDelete(event => {
    console.log('User id to be deleted: ', event.uid);

    const userID = event.uid;

    firestore.collection('cards').doc(userID).delete().then(function () {
        console.log('Deleted card for user ', userID);
        return 'Deleted card for user $userID';
    }).catch(error => {
        console.error('Error when deleting card for user $userID', error);
    });

    return firestore.collection('users').doc(userID).delete().then(function () {
        console.log('Deleted user: ', userID);
        return 'Deleted user $userID';
    }).catch(error => {
        console.error('Error when delting user! $userID', error);
    });
});

/*
exports.addItem = functions.https.onCall((data, context) => {
    const itemsCollection = firestore.collection('items');
    const snapshot = await itemsCollection.add({
        id: data['id'],
        status: data['status'],
        creator: data['creator'],
        name: data['name'],
        description: data['description'],
        type: data['type'],
        condition: data['condition'],
        price: data['price'],
        numImages: data['numImages'],
        location: data['location'],
        rental: data['rental'],
    });

    itemsCollection.doc(snapshot.documentID).update({
        id: customer.id
    });
});
*/