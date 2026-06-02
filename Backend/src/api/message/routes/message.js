module.exports = {
    routes: [
        {
            method: 'POST',
            path: '/conversations/:conversationId/messages',
            handler: 'message.sendMessage',
            config: {
                auth: false
            }
        },
        {
            method: 'GET',
            path: '/conversations/:conversationId/messages',
            handler: 'message.getMessages',
            config: {
                auth: false
            }
        },
        {
            method: 'GET',
            path: '/conversations/:conversationId/messages/:messageId',
            handler: 'message.getMessageById',
            config: {
                auth: false
            }
        },
        {
            method: 'DELETE',
            path: '/conversations/:conversationId/messages/:messageId',
            handler: 'message.deleteMessage',
            config: {
                auth: false
            }
        }
    ]
}