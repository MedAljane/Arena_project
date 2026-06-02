module.exports = {
    routes:[
        {
            method: 'POST',
            path: '/manager/create-campus',
            handler: 'campus.createCampusController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            },
        },

        {
            method: 'PUT',
            path: '/manager/update-campus/:id',
            handler: 'campus.updateCampusController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            },
        },

        {
            method: 'DELETE',
            path: '/manager/delete-campus/:id',
            handler: 'campus.deleteCampusController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            },
        },

        {
            method: 'GET',
            path: '/manager/get-campus/:id',
            handler: 'campus.getCampusByIdController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            },
        },

        {
            method: 'GET',
            path: '/manager/get-campuses',
            handler: 'campus.getCampusesController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            },
        },

        {
            method: 'GET',
            path: '/manager/get-campus-by-manager',
            handler: 'campus.getCampusByManagerController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            },
        },

        // Admin routes
        {
            method: 'GET',
            path: '/admin/get-campus-by-manager',
            handler: 'campus.getCampusByManagerController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            },
        },

        {
            method: 'GET',
            path: '/admin/get-all-campuses',
            handler: 'campus.getCampusesController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            },
        },

        // Player routes
        {
            method: 'GET',
            path: '/player/get-all-campuses',
            handler: 'campus.getCampusesController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isPlayer']
            },
        },

        {
            method: 'GET',
            path: '/player/get-campus/:id',
            handler: 'campus.getCampusByIdController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isPlayer']
            },
        },

        {
            method: 'GET',
            path: '/player/get-campus-by-manager',
            handler: 'campus.getCampusByManagerController',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isPlayer']
            },
        }


    ]
}