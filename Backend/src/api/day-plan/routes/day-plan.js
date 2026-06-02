module.exports = {
    routes: [
        {
            method: 'POST',
            path: '/manager/day-plans',
            handler: 'day-plan.create',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            },
        },
        {
            method: 'GET',
            path: '/manager/day-plans/by-date',
            handler: 'day-plan.getByDate',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            }
        },
        {
            method: 'GET',
            path: '/manager/day-plans/:id',
            handler: 'day-plan.getById',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            }
        },
        {
            method: 'DELETE',
            path: '/manager/day-plans/:id',
            handler: 'day-plan.deleteDay',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            }
        },
    ]
};