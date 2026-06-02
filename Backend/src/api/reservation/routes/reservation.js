'use strict';


module.exports = {
    routes: [
        // ── Player routes ─────────────────────────────────────────────────
        {
            method: 'POST',
            path: '/reservations',
            handler: 'reservation.create',
            config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] }
        },
        {
            method: 'PUT',
            path: '/reservations/:id',
            handler: 'reservation.update',
            config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] }
        },
        {
            method: 'PUT',
            path: '/reservations/:id/cancel',
            handler: 'reservation.cancel',
            config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] }
        },
        {
            method: 'GET',
            path: '/reservations/mine',
            handler: 'reservation.getReservationsByPlayer',
            config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] }
        },

        // ── Employee routes ───────────────────────────────────────────────
        {
            method: 'GET',
            path: '/employee/reservations',
            handler: 'reservation.getEmployeeReservations',
            config: { auth: false, policies: ['global::authMiddleware', 'global::isEmployee'] }
        },

        // ── Manager routes ────────────────────────────────────────────────
        {
            method: 'GET',
            path: '/manager/reservations',
            handler: 'reservation.getManagerReservations',
            config: { auth: false, policies: ['global::authMiddleware', 'global::isManager'] }
        },
        {
            method: 'GET',
            path: '/manager/reservations/pending',
            handler: 'reservation.getPendingReservations',
            config: { auth: false, policies: ['global::authMiddleware', 'global::isManager'] }
        },
        {
            method: 'PUT',
            path: '/manager/reservations/:id/confirm',
            handler: 'reservation.confirmReservation',
            config: { auth: false, policies: ['global::authMiddleware', 'global::isManager'] }
        },
        {
            method: 'PUT',
            path: '/manager/reservations/:id/deny',
            handler: 'reservation.denyReservation',
            config: { auth: false, policies: ['global::authMiddleware', 'global::isManager'] }
        },
    ]
};