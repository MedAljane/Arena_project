'use strict';

const { routes } = require("../../auth/routes/auth");

module.exports = {
    routes: [
        {
            method: 'POST',
            path: '/manager/week-agendas',
            handler: 'week-agenda.create',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            },
        },

        {
            method: 'POST',
            path: '/manager/week-agendas/:id/publish',
            handler: 'week-agenda.publish',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            }
        },

        {
            method: 'GET',
            path: '/admin/week-agendas',
            handler: 'week-agenda.getAll',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isAdmin']
            }
        },

        {
            method: 'DELETE',
            path: '/manager/week-agendas/:id',
            handler: 'week-agenda.deleteAgenda',
            config: {
                auth: false,
                policies: ['global::authMiddleware', 'global::isManager']
            }
        },

        {
            method: 'GET',
            path: '/week-agendas/:id',
            handler: 'week-agenda.getById',
            config: {
                auth: false,
                policies: ['global::authMiddleware']
            }
        },

        {
            method: 'GET',
            path: '/week-agendas/available-slots',
            handler: 'week-agenda.getAvailableSlots',
            config: {
                auth: false,
                policies: ['global::authMiddleware']
            }
        },

        {
            method: 'GET',
            path: '/week-agendas/terrain',
            handler: 'week-agenda.getTerrainAgenda',
            config: {
                auth: false,
                policies: ['global::authMiddleware']
            }
        },

    ]
}