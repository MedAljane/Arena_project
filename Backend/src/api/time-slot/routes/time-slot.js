'use strict';

module.exports = {
    routes: [
        {
            method: 'POST',
            path: '/time-slots',
            handler: 'time-slot.create',
            config: {
                auth: false,
                policies: [ 'global::authMiddleware' , 'global::isManager' ],
            }
        },
        {
            method: 'PUT',
            path: '/time-slots/:id',
            handler: 'time-slot.update',
            config: {
                auth: false,
                policies: [ 'global::authMiddleware' , 'global::isManager' ],
            }
        },
        {
            method: 'DELETE',
            path: '/time-slots/:id',
            handler: 'time-slot.delete',
            config: {
                auth: false,
                policies: [ 'global::authMiddleware' , 'global::isManager' ],
            }
        },
        {
            method: 'GET',
            path: '/time-slots',
            handler: 'time-slot.getTimeSlots',
            config: {
                auth: false,
                policies: [ 'global::authMiddleware' ],
            }
        },
    ]
};