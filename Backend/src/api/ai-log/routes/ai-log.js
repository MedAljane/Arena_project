'use strict';

module.exports = {
    routes: [
        {
            method:  'GET',
            path:    '/admin/ai-stats',
            handler: 'ai-log.stats',
            config: {
                auth:     false,
                policies: ['global::authMiddleware', 'global::isAdmin'],
            },
        },
        {
            method:  'GET',
            path:    '/admin/ai-logs',
            handler: 'ai-log.findLogs',
            config: {
                auth:     false,
                policies: ['global::authMiddleware', 'global::isAdmin'],
            },
        },
    ],
};
