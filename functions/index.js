const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);

const db = admin.firestore();
const settings = { timestampInSnapshots: true };
db.settings(settings);

const storage = admin.storage();
const bucket = storage.bucket();

const stripe = require('stripe')(functions.config().stripe.token);

// create new user document when account created
exports.createUser = functions.auth.user().onCreate(event => {
    console.log('User id to be created: ', event.uid);

    const userID = event.uid;
    const email = event.email;
    var photoURL = event.photoURL;

    if (photoURL === null) {
        photoURL = 'https://firebasestorage.googleapis.com/v0/b/shareapp-rrd.appspot.com/o/profile_pics%2Fnew_user.png?alt=media&token=60762aec-fa4f-42cd-9d4b-656bd92aeb6d';
    } else {
        photoURL = photoURL.replace('s96-c', 's960-c');
    }

    const name = event.displayName || 'new user';
    const creationDate = Date.now();

    return db.collection('users').doc(userID).set({
        email: email,
        avatar: photoURL,
        name: name,
        lastActive: Date.now(),
        creationDate: creationDate,
        custId: 'new',
        defaultSource: null,
        pushToken: [],
        description: '',
        gender: null,
        phoneNum: null,
        birthday: null,
        address: null,
        verified: false,
        acceptedTOS: false,
        totalRating: 0,
        numRatings: 0,
    }).then(function () {
        console.log('Created user: ', userID);
        return `Created user ${userID}`;
    }).catch(error => {
        console.error('Error when creating user! ', error);
    });
});

// delete user account in firestore when account deleted
exports.deleteUser = functions.auth.user().onDelete(event => {
    console.log('User id to be deleted: ', event.uid);

    const userID = event.uid;
    const filePath = `profile_pics/${userID}`;
    const file = bucket.file(filePath);

    file.delete().then(() => {
        console.log(`Successfully deleted profile pic with user id: ${userID} at path ${filePath}`);
        return 'Delete photo profile pic success';
    }).catch(err => {
        console.error(`Failed to remove images, error: ${err}`);
    });

    return db.collection('users').doc(userID).delete().then(function () {
        console.log('Deleted user: ', userID);
        return 'Deleted user $userID';
    }).catch(error => {
        console.error('Error when delting user! $userID', error);
    });
});

// delete profile pic and user account from authentication when user document is deleted
exports.deleteUserAccount = functions.firestore
    .document('users/{userID}')
    .onDelete((snap, context) => {
        const userID = snap.id;
        const filePath = `profile_pics/${userID}`;
        const file = bucket.file(filePath);

        file.delete().then(() => {
            console.log(`Successfully deleted avatar with user id: ${userID} at path ${filePath}`);
            return 'Delete avatar success';
        }).catch(err => {
            console.error(`Failed to remove images, error: ${err}`);
        });

        return admin.auth().deleteUser(snap.id)
            .then(() => console.log('Deleted user with ID:' + snap.id))
            .catch((error) => console.error('There was an error while deleting user:', error));
    });

// delete images from item in firebase storage when item document deleted
exports.deleteItemImages = functions.firestore.document('items/{itemId}')
    .onDelete(async (snap, context) => {
        const deletedValue = snap.data();
        const id = deletedValue.id;

        if (id === null) {
            return null;
        }

        console.log(`itemId to be deleted: ${id}`);

        bucket.deleteFiles({
            prefix: `items/${id}/`
        }, function (err) {
            if (!err) {
                console.log(`Successfully deleted images with item id: ${id}`);
            } else {
                console.error(`Failed to remove images, error: ${err}`);
            }
        });
    })

// chat push notifications
exports.chatNotification = functions.firestore.document('messages/{groupChatId}/messages/{msgTimestamp}')
    .onCreate(async (snapshot, context) => {
        var msgData = snapshot.data();
        var token = msgData.pushToken;

        if (token === null) {
            console.log('Other user has no push token');
        } else {
            var payload = {
                "notification": {
                    "title": msgData.nameFrom,
                    "body": msgData.content,
                    "sound": "default",
                },
                "data": {
                    "type": "chat",
                    "idFrom": msgData.idFrom,
                    "idTo": msgData.idTo,
                    "nameFrom": msgData.nameFrom,
                    "message": msgData.content,
                    "groupChatId": context.params.groupChatId,
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                }
            }

            return admin.messaging().sendToDevice(token, payload).then((response) => {
                console.log('Push success');
                return 'Success';
            }).catch((err) => {
                console.log(err);
                return err;
            });
        }
    })

// new rental notification
exports.newRentalNotification = functions.firestore.document('rentals/{rentalId}')
    .onCreate(async (snapshot, context) => {
        var msgData = snapshot.data();
        var initialPushNotif = msgData.initialPushNotif;
        var token = initialPushNotif.pushToken;

        if (token === null) {
            console.log('Other user has no push token');
        } else {
            var payload = {
                "notification": {
                    "title": `${initialPushNotif.nameFrom} is requesting to rent your ${initialPushNotif.itemName}`,
                    "body": ``,
                    "sound": "default",
                },
                "data": {
                    "type": "rental",
                    "rentalID": context.params.rentalId,
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                }
            }

            return admin.messaging().sendToDevice(token, payload).then((response) => {
                console.log('Push success');
                return 'Success';
            }).catch((err) => {
                console.log(err);
                return err;
            });
        }
    })

// push notifications in 'notifications' collection
exports.pushNotifications = functions.firestore.document('notifications/{notificationId}')
    .onCreate(async (snapshot, context) => {
        var msgData = snapshot.data();
        var token = msgData.pushToken;

        if (token === null) {
            console.log('Other user has no push token');
        } else {
            var payload = {
                "notification": {
                    "title": msgData.title,
                    "body": msgData.body,
                    "sound": "default",
                },
                "data": {
                    "type": "rental",
                    "rentalID": msgData.rentalID,
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                }
            }

            return admin.messaging().sendToDevice(token, payload).then((response) => {
                console.log('Push success');
                return 'Success';
            }).catch((err) => {
                console.log(err);
                return err;
            });
        }
    })

// add stripe source when new card added
exports.addStripeSource = functions.firestore.document('users/{userId}/tokens/{tokenId}')
    .onWrite(async (tokenSnap, context) => {
        var customer;
        const data = tokenSnap.after.data();

        if (data === null) {
            return null
        }

        const token = data.tokenId;
        const snapshot = await db.collection('users').doc(context.params.userId).get();
        const customerId = snapshot.data().custId;
        const customerEmail = snapshot.data().email;

        if (customerId === 'new') {
            customer = await stripe.customers.create({
                email: customerEmail,
                source: token,
            });

            const customerSource = customer.sources.data[0];
            const customerSourceId = customerSource.id;

            db.collection('users').doc(context.params.userId).update({
                custId: customer.id,
                defaultSource: customerSourceId,
            });

            db.collection('users').doc(context.params.userId).collection('sources').
                doc(customerSource.card.fingerprint).set(customerSource, {
                    merge: true
                });

        } else {
            customer = await stripe.customers.retrieve(customerId);

            var newSource = await stripe.customers.createSource(
                customerId,
                {
                    source: token,
                },
            );

            var updatedCustomer = await stripe.customers.retrieve(
                customerId,
            );

            var newDefaultSource = updatedCustomer.default_source;
            console.log(`New default source: ${newDefaultSource}`);

            await db.collection('users').doc(context.params.userId).update({
                defaultSource: newDefaultSource,
            });

            await db.collection('users').doc(context.params.userId).collection('sources').
                doc(newSource.card.fingerprint).set(newSource, {
                    merge: true
                });
        }

        /*
        const customerSource = customer.sources.data[0];
        
        return firestore.collection('users').doc(context.params.userId).collection('sources').
            doc(customerSource.card.fingerprint).set(customerSource, {
                merge: true
            });
        */
    })

// delete credit card
exports.deleteStripeSource = functions.https.onCall(async (data, context) => {
    var customerId = data.customerId;
    var source = data.source;
    var userId = data.userId;

    await stripe.customers.deleteSource(
        customerId,
        source,
    );

    var updatedCustomer = await stripe.customers.retrieve(
        customerId,
    );

    var newDefaultSource = updatedCustomer.default_source;
    console.log(`New default source: ${newDefaultSource}`);

    var resp = await db.collection('users').doc(userId).update({
        defaultSource: newDefaultSource,
    });

    if (resp === null) {
        return 'Error';
    } else {
        return 'Card successfully deleted';
    }
});

// set card as default
exports.setDefaultSource = functions.https.onCall(async (data, context) => {
    var userId = data.userId;
    var customerId = data.customerId;
    var newSourceId = data.newSourceId;

    var updatedCustomer = await stripe.customers.update(customerId, {
        default_source: newSourceId
    });

    var resp = await db.collection('users').doc(userId).update({
        defaultSource: updatedCustomer.default_source,
    });

    if (resp === null) {
        return 'Error';
    } else {
        return 'Updated default payment method';
    }
});

/*
exports.setDefaultSource = (userId, customerId, newSourceId) => {
    var updatedCustomer = await stripe.customers.update(customerId, {
        default_source: newSourceId
    });

    await firestore.collection('users').doc(userId).update({
        defaultSource: updatedCustomer.default_source,
    });
};
*/

exports.createCharge = functions.firestore.document('charges/{chargeId}')
    .onCreate(async (chargeSnap, context) => {
        try {
            const idFrom = chargeSnap.data().rentalData['idFrom'];
            const userSnap = await db.collection('users').doc(idFrom).get();
            const customer = userSnap.data().custId;
            const amount = chargeSnap.data().amount;
            const currency = chargeSnap.data().currency;
            const description = chargeSnap.data().description;

            /*
            application_fee_amount: 123,
            transfer_data: {
                amount: 877,
                destination: "{{CONNECTED_STRIPE_ACCOUNT_ID}}",
                },
            */

            const charge = { amount, currency, customer, description };
            const idempotentKey = context.params.chargeId;

            const response = await stripe.charges.create(charge, { idempotency_key: idempotentKey });
            return chargeSnap.ref.set(response, { merge: true });

        } catch (error) {
            await chargeSnap.ref.set({ error: error.message }, { merge: true });
        }
    });

// update items and rentals when user edits their name and profile picture
exports.updateUserConnections = functions.firestore
    .document('users/{userId}')
    .onUpdate((userSnap, context) => {
        const userId = context.params.userId;
        const oldSnap = userSnap.before.data();
        const newSnap = userSnap.after.data();
        var updateName = 0;
        var updateAvatar = 0;

        if (oldSnap === null || newSnap === null) {
            return;
        }

        var oldName = oldSnap.name;
        var oldAvatar = oldSnap.avatar;

        var newName = newSnap.name;
        var newAvatar = newSnap.avatar;

        if (oldName !== newName) {
            // Name needs updating
            updateName = 1;
        }

        if (oldAvatar !== newAvatar) {
            // Avatar needs updating
            updateAvatar = 1;
        }

        if (updateName || updateAvatar) {
            let batch = db.batch();
            var creatorRef = db.collection('users').doc(userId);

            // update all items the user owns
            return db.collection('items').where('creator', '==', creatorRef).get()
                .then(snapshot => {
                    snapshot.forEach(doc => {
                        batch.update(doc.ref, {
                            owner: {
                                name: newName,
                                avatar: newAvatar,
                            }
                        });
                    });

                    return null;
                })

                .then(() => {
                    return db.collection('messages').where('users', 'array-contains', userId).get();
                })

                .then(snapshot => {
                    // update chat rooms the user is in
                    snapshot.forEach(doc => {
                        var users = doc.data().users;
                        if (userId === users[0]) {
                            batch.update(doc.ref, {
                                user0: {
                                    name: newName,
                                    avatar: newAvatar,
                                }
                            });
                        }

                        if (userId === users[1]) {
                            batch.update(doc.ref, {
                                user1: {
                                    name: newName,
                                    avatar: newAvatar,
                                }
                            });
                        }
                    });

                    return null;
                })

                .then(() => {
                    var date = admin.firestore.Timestamp.now();
                    var userRef = db.collection('users').doc(userId);
                    return db.collection('rentals').where('users', 'array-contains', userRef)
                        .where('rentalEnd', '>', date).get();
                })

                .then(snapshot => {
                    // update the rentals the user is involved in                    
                    snapshot.forEach(doc => {
                        var ownerRef = doc.data().owner;
                        var renterRef = doc.data().renter;
                        console.log(`Owner ref: ${ownerRef}`);
                        console.log(`Owner ref id: ${ownerRef.id}`);
                        console.log(`Doc: ${doc.data()}`);

                        if (userId === ownerRef.id) {
                            batch.update(doc.ref, {
                                ownerData: {
                                    name: newName,
                                    avatar: newAvatar,
                                }
                            });
                        }

                        if (userId === renterRef.id) {
                            batch.update(doc.ref, {
                                renterData: {
                                    name: newName,
                                    avatar: newAvatar,
                                }
                            });
                        }
                    });

                    return null;
                })

                .then(() => {
                    return batch.commit();
                })

                .then(() => {
                    console.log("Success");
                    return null;
                })

                .catch(err => {
                    console.log(err);
                });
        }

        return 'Success';
    });

// update items and rentals when user edits their name and profile picture
exports.updateItemConnections = functions.firestore
    .document('items/{itemId}')
    .onUpdate((itemSnap, context) => {
        const itemId = context.params.itemId;
        const oldSnap = itemSnap.before.data();
        const newSnap = itemSnap.after.data();
        var updateName = 0;
        var updateAvatar = 0;

        if (oldSnap === null || newSnap === null) {
            return;
        }

        var oldName = oldSnap.name;
        var oldAvatar = oldSnap.avatar;

        var newName = newSnap.name;
        var newAvatar = newSnap.avatar;

        if (oldName !== newName) {
            // Name needs updating
            updateName = 1;
        }

        if (oldAvatar !== newAvatar) {
            // Avatar needs updating
            updateAvatar = 1;
        }

        if (updateName || updateAvatar) {
            let batch = db.batch();
            var itemRef = db.collection('items').doc(itemId);
            var date = admin.firestore.Timestamp.now();

            // update all rentals involving the item (excluding past rentals)
            return db.collection('rentals').where('item', '==', itemRef)
                .where('rentalEnd', '>', date).get()
                .then(snapshot => {
                    snapshot.forEach(doc => {
                        batch.update(doc.ref, {
                            itemName: newName,
                            itemAvatar: newAvatar,
                        });
                    });

                    return null;
                })

                .then(() => {
                    return batch.commit();
                })

                .then(() => {
                    console.log("Success");
                    return null;
                })

                .catch(err => {
                    console.log(err);
                });
        }

        return 'Success';
    });

exports.updateMessageData = functions.firestore
    .document('messages/{chatRoomId}/messages/{messageId}')
    .onCreate((messageSnap, context) => {
        const chatRoomId = context.params.chatRoomId;
        const messageId = context.params.messageId;
        const timestamp = messageSnap.data().timestamp;
        const content = messageSnap.data().content;

        var messageRef = db.collection('messages').doc(chatRoomId);
        let batch = db.batch();

        batch.update(messageRef, {
            lastSent: {
                content: content,
                timestamp: timestamp,
            }
        });

        return batch.commit();
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