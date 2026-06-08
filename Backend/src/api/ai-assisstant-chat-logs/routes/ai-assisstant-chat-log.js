'use strict';

module.exports = {
    routes: [
        {
            method:  'GET',
            path:    '/admin/ai-stats',
            handler: 'ai-assisstant-chat-log.stats',
            config: {
                auth:     false,
                policies: ['global::authMiddleware', 'global::isAdmin'],
            },
        },
        {
            method:  'GET',
            path:    '/admin/ai-assisstant-chat-log',
            handler: 'ai-assisstant-chat-log.findLogs',
            config: {
                auth:     false,
                policies: ['global::authMiddleware', 'global::isAdmin'],
            },
        },
    ],
};
