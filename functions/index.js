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