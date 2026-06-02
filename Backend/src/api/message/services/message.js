const firebaseService = require('../../../firebase/firebase.service');

async function sendMessage( data ) {

    const db = firebaseService.getFirestore();

    const { conversationId, senderUid, text, type } = data;

    const messagesRef = db.collection('conversations').doc(String(conversationId)).collection('messages');

    const newMessage = {
        senderUid,
        text,
        type: type || 'text',
        createdAt: new Date(),
    };

    await messagesRef.add(newMessage);

    await db.collection('conversations')
    .doc(String(conversationId))
    .set({
        lastMessage: text,
        lastMessageAt: new Date(),
    }, { merge: true });
}

async function getMessages( conversationId ) {

    try {
        const db = firebaseService.getFirestore();
        
        console.log(`Fetching messages for conversation ID: ${conversationId}`);

        const snapshot = await db.collection('conversations')
            .doc(String(conversationId))
            .collection('messages')
            .orderBy('createdAt', 'asc')
            .get();

        if (snapshot.empty) {
            console.log(`No messages found for conversation ID: ${conversationId}`);
            return [];
        }

        const messages = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        console.log(`Fetched ${messages.length} messages for conversation ID: ${conversationId}`);
        return messages;
    } catch (error) {
        console.error(`Error fetching messages for conversation ID: ${conversationId}`, error);
        throw error;
    }
}

async function getMessageById( conversationId, messageId ) {
    try {
        const db = firebaseService.getFirestore();

        console.log(`Fetching message ID: ${messageId} for conversation ID: ${conversationId}`);

        const doc = await db.collection('conversations')
            .doc(String(conversationId))
            .collection('messages')
            .doc(String(messageId))
            .get();

        if (!doc.exists) {
            console.log(`Message ID: ${messageId} not found for conversation ID: ${conversationId}`);
            return null;
        }

        console.log(`Fetched message ID: ${messageId} for conversation ID: ${conversationId}`);
        return { id: doc.id, ...doc.data() };
    } catch (error) {
        console.error(`Error fetching message ID: ${messageId} for conversation ID: ${conversationId}`, error);
        throw error;
    }
}

async function deleteMessage( conversationId, messageId ) {
    try {
        const db = firebaseService.getFirestore();

        console.log(`Deleting message ID: ${messageId} for conversation ID: ${conversationId}`);

        await db.collection('conversations')
            .doc(String(conversationId))
            .collection('messages')
            .doc(String(messageId))
            .delete();

        console.log(`Deleted message ID: ${messageId} for conversation ID: ${conversationId}`);

        return { success: true };
    } catch (error) {
        console.error(`Error deleting message ID: ${messageId} for conversation ID: ${conversationId}`, error);
        throw error;
    }
}

module.exports = {
    sendMessage,
    getMessages,
    getMessageById,
    deleteMessage
}