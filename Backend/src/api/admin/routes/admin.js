const { routes } = require("../../auth/routes/auth");

module.exports = {
    routes: [
        {
            method: 'POST',
            path: '/admin/register-admin',
            handler: 'admin.registerAdmin',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            },
        },

        {
            method: 'PUT',
            path: '/admin/update-admin/:id',
            handler: 'admin.updateAdmin',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            },
        },

        {
            method: 'DELETE',
            path: '/admin/delete-admin/:id',
            handler: 'admin.deleteAdmin',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            },
        },

        {
            method: 'GET',
            path: '/admin/admins',
            handler: 'admin.getAdmins',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            },
        }

    ]
}