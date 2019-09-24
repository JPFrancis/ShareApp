const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);

const db = admin.firestore();
const settings = { timestampInSnapshots: true };
db.settings(settings);

const storage = admin.storage();
const bucket = storage.bucket();

const stripe = require('stripe')(functions.config().stripe.token);

const error_message = 'Invalid input. Make sure you\'re using the latest version of the app';

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
        pushToken: '',
        description: '',
        gender: null,
        phoneNum: null,
        birthday: null,
        address: null,
        verified: false,
        acceptedTOS: false,
        renterRating: {
            total: 0,
            count: 0,
        },
        ownerRating: {
            total: 0,
            count: 0,
        },
    }).then(function () {
        console.log('Created user: ', userID);
        return `Created user ${userID}`;
    }).catch(error => {
        console.error('Error when creating user!', error);
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
        const id = context.params.itemId;

        if (id === undefined) {
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
            console.log(`customerId: ${customerId}`);
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
            const idTo = chargeSnap.data().rentalData['idTo'];
            const itemOwner = await db.collection('users').doc(idTo).get();
            const ownerCustId = userSnap.data().custId;
            const customer = userSnap.data().custId;
            const amount = chargeSnap.data().amount;
            const currency = chargeSnap.data().currency;
            const description = chargeSnap.data().description;
            const transferDataMap = chargeSnap.data().transferData;
            const ourFee = transferDataMap['ourFee'];
            const ownerPayout = transferDataMap['ownerPayout'];
            const idempotentKey = context.params.chargeId;

            /*
            stripe.tokens.create({
                customer: "cus_YGGG4Kcl9D5BJ3",
            }, {
                    stripe_account: "{{CONNECTED_STRIPE_ACCOUNT_ID}}",
                }).then(function (token) {
                    // asynchronously called
                });
            */

            const response = await stripe.charges.create({
                amount: amount,
                currency: currency,
                //source: customer,
                source: "tok_visa",
                application_fee_amount: ourFee,
                transfer_data: {
                    amount: ownerPayout,
                    destination: ownerCustId,
                },
                description: description,
            }, { idempotency_key: idempotentKey });
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

// update items and users when rental reviews are submitted
exports.updateRatings = functions.firestore
    .document('rentals/{rentalId}')
    .onUpdate((rentalSnap, context) => {
        const rentalId = context.params.rentalId;
        const oldSnap = rentalSnap.before.data();
        const newSnap = rentalSnap.after.data();
        var updateRenter = 0;
        var updateOwner = 0;
        var itemAverage = 0;

        if (oldSnap === undefined || newSnap === undefined) {
            return;
        }

        var oldRenterReview = oldSnap.renterReviewSubmitted;
        var oldOwnerReview = oldSnap.ownerReviewSubmitted;

        var newRenterReview = newSnap.renterReviewSubmitted;
        var newOwnerReview = newSnap.ownerReviewSubmitted;

        if (oldRenterReview !== newRenterReview) {
            updateRenter = 1;
        }

        if (oldOwnerReview !== newOwnerReview) {
            updateOwner = 1;
            itemAverage = newSnap.ownerReview.average;
        }

        let batch = db.batch();

        if (updateRenter) {
            var renterRef = newSnap.renter;
            var renterRating = newSnap.renterReview.rating;

            batch.update(renterRef, {
                "renterRating.count": admin.firestore.FieldValue.increment(1),
                "renterRating.total": admin.firestore.FieldValue.increment(renterRating),
            });
        }

        if (updateOwner) {
            var itemRef = newSnap.item;
            var ownerRef = newSnap.owner;

            // update item ratings
            batch.update(itemRef, {
                numRatings: admin.firestore.FieldValue.increment(1),
                rating: admin.firestore.FieldValue.increment(itemAverage),
            });

            // update item owner ratings
            batch.update(ownerRef, {
                "ownerRating.count": admin.firestore.FieldValue.increment(1),
                "ownerRating.total": admin.firestore.FieldValue.increment(itemAverage),
            });
        }

        batch.commit();

        return 'Success';
    });

// if a rental is deleted, remove item and user ratings if review is there
exports.removeRatings = functions.firestore
    .document('rentals/{rentalId}')
    .onDelete((rentalSnap, context) => {
        const rentalId = context.params.rentalId;
        var renterRating;

        if (rentalSnap.data().renterReview !== null) {
            renterRating = rentalSnap.data().renterReview.rating;
        }

        var itemAverage;

        if (rentalSnap.data().ownerReview !== null) {
            itemAverage = rentalSnap.data().ownerReview.average;
        }

        var renterRef = rentalSnap.data().renter;
        var itemRef = rentalSnap.data().item;
        var ownerRef = rentalSnap.data().owner;
        let batch = db.batch();

        if (renterRating !== undefined) {
            // remove renter rating            
            batch.update(renterRef, {
                "renterRating.count": admin.firestore.FieldValue.increment(-1),
                "renterRating.total": admin.firestore.FieldValue.increment(renterRating * -1.0),
            });
        }

        if (itemAverage !== undefined) {
            // remove item ratings
            batch.update(itemRef, {
                numRatings: admin.firestore.FieldValue.increment(-1),
                rating: admin.firestore.FieldValue.increment(itemAverage * -1.0),
            });


            // remove item owner ratings
            batch.update(ownerRef, {
                "ownerRating.count": admin.firestore.FieldValue.increment(-1),
                "ownerRating.total": admin.firestore.FieldValue.increment(itemAverage * -1.0),
            });
        }

        batch.commit();

        return 'Success';
    });

exports.createChatRoom = functions.https.onCall(async (data, context) => {
    var users = data.users;
    var user0 = data.user0;
    var user0Name = user0.name;
    var user0Avatar = user0.avatar;
    var user1 = data.user1;
    var user1Name = user1.name;
    var user1Avatar = user1.avatar;
    var combinedId = data.combinedId;

    if (users === undefined || user0Name === undefined || user0Avatar === undefined ||
        user1Name === undefined || user1Avatar === undefined || combinedId === undefined) {
        throw new functions.https.HttpsError('unknown', error_message);
    } else {
        var docRef = db.collection('messages').doc(combinedId);

        let resp = await docRef.set({
            users: users,
            user0: {
                name: user0Name,
                avatar: user0Avatar
            },
            user1: {
                name: user1Name,
                avatar: user1Avatar
            },
        });

        if (resp === null) {
            throw new functions.https.HttpsError('unknown', 'Error creating chat room');
        } else {
            return await docRef.get();
        }
    }
});

exports.addItem = functions.https.onCall(async (data, context) => {
    var status = data.status;
    var creator = data.creator;
    var name = data.name;
    var description = data.description;
    var type = data.type;
    var condition = data.condition;
    var rating = data.rating;
    var numRatings = data.numRatings;
    var price = data.price;
    var images = data.images;
    var numImages = data.numImages;
    var geohash = data.geohash;
    var lat = data.lat;
    var long = data.long;
    var searchKey = data.searchKey;
    var isVisible = data.isVisible;
    var owner = data.owner;
    var ownerName = owner.name;
    var ownerAvatar = owner.avatar;

    if (status === undefined || creator === undefined || name === undefined || description === undefined ||
        type === undefined || condition === undefined || rating === undefined || numRatings === undefined ||
        price === undefined || images === undefined || numImages === undefined || geohash === undefined ||
        lat === undefined || long === undefined || searchKey === undefined || isVisible === undefined ||
        owner === undefined || ownerName === undefined || ownerAvatar === undefined) {
        throw new functions.https.HttpsError('unknown', error_message);
    } else {
        var docRef = await db.collection('items').add({
            created: new Date(),
            status: status,
            creator: db.collection('users').doc(creator),
            name: name,
            description: description,
            type: type,
            condition: condition,
            rating: rating,
            numRatings: numRatings,
            price: price,
            images: images,
            numImages: numImages,
            location: {
                geohash: geohash,
                geopoint: new admin.firestore.GeoPoint(lat, long),
            },
            searchKey: searchKey,
            isVisible: isVisible,
            owner: {
                name: ownerName,
                avatar: ownerAvatar,
            },
            unavailable: null,
        });

        if (docRef === null) {
            throw new functions.https.HttpsError('unknown', 'Error creating item');
        } else {
            return docRef.id;
        }
    }
});

exports.updateItem = functions.https.onCall(async (data, context) => {
    var itemId = data.itemId;
    var name = data.name;
    var description = data.description;
    var type = data.type;
    var condition = data.condition;
    var price = data.price;
    var numImages = data.numImages;
    var geohash = data.geohash;
    var lat = data.lat;
    var long = data.long;
    var searchKey = data.searchKey;

    if (itemId === undefined || name === undefined || description === undefined || type === undefined ||
        condition === undefined || price === undefined || numImages === undefined || geohash === undefined ||
        lat === undefined || long === undefined || searchKey === undefined) {
        throw new functions.https.HttpsError('unknown', error_message);
    } else {
        let itemRef = db.collection('items').doc(itemId);

        var update = await itemRef.update({
            name: name,
            description: description,
            type: type,
            condition: condition,
            price: price,
            numImages: numImages,
            location: {
                geohash: geohash,
                geopoint: new admin.firestore.GeoPoint(lat, long),
            },
            searchKey: searchKey,
        });

        if (update === null) {
            throw new functions.https.HttpsError('unknown', 'Error updating item');
        } else {
            return 'Item update successful';
        }
    }
});

exports.createRental = functions.https.onCall(async (data, context) => {
    var status = data.status;
    var requesting = data.requesting;
    var item = data.item;
    var itemName = data.itemName;
    var type = data.type;
    var condition = data.condition;
    var rating = data.rating;
    var numRatings = data.numRatings;
    var price = data.price;
    var images = data.images;
    var numImages = data.numImages;
    var geohash = data.geohash;
    var lat = data.lat;
    var long = data.long;
    var searchKey = data.searchKey;
    var isVisible = data.isVisible;
    var owner = data.owner;
    var ownerName = owner.name;
    var ownerAvatar = owner.avatar;

    if (status === undefined || creator === undefined || name === undefined || description === undefined ||
        type === undefined || condition === undefined || rating === undefined || numRatings === undefined ||
        price === undefined || images === undefined || numImages === undefined || geohash === undefined ||
        lat === undefined || long === undefined || searchKey === undefined || isVisible === undefined ||
        owner === undefined || ownerName === undefined || ownerAvatar === undefined) {
        throw new functions.https.HttpsError('unknown', error_message);
    } else {
        var docRef = await db.collection('items').add({
            created: new Date(),
            status: status,
            creator: db.collection('users').doc(creator),
            name: name,
            description: description,
            type: type,
            condition: condition,
            rating: rating,
            numRatings: numRatings,
            price: price,
            images: images,
            numImages: numImages,
            location: {
                geohash: geohash,
                geopoint: new admin.firestore.GeoPoint(lat, long),
            },
            searchKey: searchKey,
            isVisible: isVisible,
            owner: {
                name: ownerName,
                avatar: ownerAvatar,
            },
            unavailable: null,
        });

        if (docRef === null) {
            throw new functions.https.HttpsError('unknown', 'Error creating item');
        } else {
            return docRef.id;
        }
    }
});