const { routes } = require("../../auth/routes/auth");

module.exports = {
    routes: [
        {
            method: 'POST',
            path: '/admin/register-manager',
            handler: 'manager.registerManager',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            },
        },

        {
            method: 'PUT',
            path: '/admin/update-manager/:id',
            handler: 'manager.updateManager',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            },
        },

        {
            method: 'DELETE',
            path: '/admin/delete-manager/:id',
            handler: 'manager.deleteManager',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            },
        },

        {
            method: 'GET',
            path: '/admin/managers',
            handler: 'manager.getManagers',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            },
        },


        // ── Self-service (manager acts on own profile) ────────────────────────
        {
            method: 'GET',
            path: '/manager/me',
            handler: 'manager.getMe',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            },
        },
        {
            method: 'PUT',
            path: '/manager/me',
            handler: 'manager.updateMe',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            },
        },

        // Additional route to get all managers with their profiles
        {
            method: 'GET',
            path: '/player/managers',
            handler: 'manager.getManagers',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isPlayer']
            },
        }

    ]
}