'use strict';

const aiService = require('../services/ai');

module.exports = {

    
    async playerChat(ctx) {
        const userAuthId = ctx.state.user.id;
        const { message, history = [], sessionId = '' } = ctx.request.body;

        if (!message || typeof message !== 'string' || message.trim() === '') {
            return ctx.badRequest('message is required');
        }

        try {
            const result = await aiService.playerChat(
                userAuthId, message.trim(), history, sessionId);
            ctx.send(result);
        } catch (err) {
            console.error('[AI] playerChat error:', err);
            ctx.badRequest(err.message || 'AI service error');
        }
    },

    
    async managerChat(ctx) {
        const userAuthId = ctx.state.user.id;
        const { message, history = [], sessionId = '' } = ctx.request.body;

        if (!message || typeof message !== 'string' || message.trim() === '') {
            return ctx.badRequest('message is required');
        }

        try {
            const result = await aiService.managerChat(
                userAuthId, message.trim(), history, sessionId);
            ctx.send(result);
        } catch (err) {
            console.error('[AI] managerChat error:', err);
            ctx.badRequest(err.message || 'AI service error');
        }
    },
};
