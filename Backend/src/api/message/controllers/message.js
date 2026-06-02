const messageService = require('../services/message');

module.exports = {
    async sendMessage(ctx) {
        const { conversationId, senderUid, text, type } = ctx.request.body;
        if (!conversationId || !senderUid || !text) {
            ctx.throw(400, 'conversationId, senderUid and text are required');
        }
        await messageService.sendMessage({ conversationId, senderUid, text, type });
        ctx.send({ success: true });
    },

    async getMessages(ctx) {
        const { conversationId } = ctx.params;
        if (!conversationId) {
            ctx.throw(400, 'conversationId is required');
        }
        const messages = await messageService.getMessages(conversationId);
        ctx.send(messages);
    },

    async getMessageById(ctx) {
        const { conversationId, messageId } = ctx.params;
        if (!conversationId || !messageId) {
            ctx.throw(400, 'conversationId and messageId are required');
        }
        const message = await messageService.getMessageById(conversationId, messageId);
        if (!message) {
            ctx.throw(404, 'Message not found');
        }
        ctx.send(message);
    },

    async deleteMessage(ctx) {
        const { conversationId, messageId } = ctx.params;
        if (!conversationId || !messageId) {
            ctx.throw(400, 'conversationId and messageId are required');
        }
        await messageService.deleteMessage(conversationId, messageId);
        ctx.send({ success: true });
    }
}