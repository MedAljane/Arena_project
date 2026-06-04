'use strict';

/**
 * Writes one AI turn (user message → AI reply + tool calls) to ai_logs.
 * Called from ai.js after every playerChat / managerChat.
 */
async function logTurn({
    userAuthId,
    userRole,
    provider,
    model,
    userMessage,
    aiReply,
    toolsUsed     = [],
    actionsTaken  = [],
    tokensUsed    = 0,
    processingMs  = 0,
    success       = true,
    errorMessage  = null,
    sessionId,
}) {
    try {
        await strapi.db.query('api::ai-log.ai-log').create({
            data: {
                userId:             { connect: [{ id: userAuthId }] },
                userRole,
                provider,
                model,
                userMessage,
                aiReply,
                toolsUsed,
                actionsTaken,
                tokensUsed,
                processingMs,
                success,
                errorMessage,
                sessionId,
                createdAtTimestamp: new Date(),
                publishedAt:        new Date(), // required — draftAndPublish is enabled
            },
        });
    } catch (err) {
        // Logging must never crash the main chat flow
        console.error('[ai-log] Failed to save log entry:', err.message);
    }
}

module.exports = { logTurn };
