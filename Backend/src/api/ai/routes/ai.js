'use strict';

module.exports = {
    routes: [
        {
            method: 'POST',
            path:    '/ai/player-chat',
            handler: 'ai.playerChat',
            config: {
                auth:     false,
                policies: ['global::authMiddleware', 'global::isPlayer'],
            },
        },
        {
            method: 'POST',
            path:    '/ai/manager-chat',
            handler: 'ai.managerChat',
            config: {
                auth:     false,
                policies: ['global::authMiddleware', 'global::isManager'],
            },
        },
    ],
};
