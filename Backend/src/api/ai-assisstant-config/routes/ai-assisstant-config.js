'use strict';

module.exports = {
    routes: [
        {
            method:  'GET',
            path:    '/admin/ai-config',
            handler: 'ai-assisstant-config.getConfigs',
            config: {
                auth:     false,
                policies: ['global::authMiddleware', 'global::isAdmin'],
            },
        },
        {
            method:  'PUT',
            path:    '/admin/ai-config/:role',
            handler: 'ai-assisstant-config.upsertConfig',
            config: {
                auth:     false,
                policies: ['global::authMiddleware', 'global::isAdmin'],
            },
        },
    ],
};
