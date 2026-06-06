const admin = require('firebase-admin');

let firebaseApp = null;
function getFirebaseApp() {
    if (firebaseApp) return firebaseApp;
    firebaseApp = admin.initializeApp({ 
        credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL, 
            privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'), 
        }), 
    }); 
    return firebaseApp; 
}

function getFirestore() {
    return getFirebaseApp().firestore();
}

async function createConversation({
    reservationId,
    playerUid,
    employeeUid,
    playerId,
    employeeId,
    playerName,
    employeeName,
    terrainType,
}){
    const db = getFirestore();
    const ref = db.collection('conversations').doc(String(reservationId));

    const snap = await ref.get();
    if(snap.exists) {
        console.log(`Conversation for reservation ${reservationId} already exists`);
        return snap.data();
    }

    await ref.set({
        reservationId: String(reservationId),
        participants: [playerUid, employeeUid],
        participantsIds: {
            player:   String(playerId),
            employee: String(employeeId),
        },
        participantNames: {
            player:   playerName   || `Player ${playerId}`,
            employee: employeeName || `Employee ${employeeId}`,
        },
        terrainType:   terrainType || null,
        lastMessage:   null,
        lastMessageAt: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return ref;
}

async function notifyConversationCreated(){
    console.log('Conversation created (to implement later)');
}

module.exports = {
    getFirestore,
    createConversation,
    notifyConversationCreated
}