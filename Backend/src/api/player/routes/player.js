'use strict';

module.exports = {
    routes: [
        // ── Self-service (player acts on own profile) ─────────────────────────
        {
            method: 'GET',
            path: '/player/me',
            handler: 'player.getMe',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isPlayer'],
            },
        },
        {
            method: 'PUT',
            path: '/player/me',
            handler: 'player.updateMe',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isPlayer'],
            },
        },

        // ── Admin management ──────────────────────────────────────────────────
        {
            method: 'GET',
            path: '/admin/players',
            handler: 'player.getPlayers',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin'],
            },
        },
        {
            method: 'POST',
            path: '/admin/register-player',
            handler: 'player.registerPlayer',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin'],
            },
        },
        {
            method: 'PUT',
            path: '/admin/update-player/:id',
            handler: 'player.updatePlayer',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin'],
            },
        },
        {
            method: 'DELETE',
            path: '/admin/delete-player/:id',
            handler: 'player.deletePlayer',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin'],
            },
        },
    ],
};
