'use strict';
module.exports = {

    
    async createReservation({ userAuthId, timeSlotId, campusId, terrainId, type, notes }) {

        const playerProfile = await strapi.db.query('api::player.player').findOne({ where: { user: userAuthId } });

        if (!playerProfile) {
            throw new Error('Player profile not found for the authenticated user.');
        }

        const terrain = await strapi.db.query('api::terrain.terrain').findOne({
            where: {
                id: terrainId,
                campus: { id: campusId }
            }
        });

        if (!terrain) {
            throw new Error('Terrain not found.');
        }

        const campus = await strapi.db.query('api::campus.campus').findOne({ where: { id: campusId }, populate: ['manager'] });

        if (!campus) {
            throw new Error('Campus not found.');
        }

        const slot = await strapi.db.query('api::time-slot.time-slot').findOne({
            where: { id: timeSlotId },
            populate: {
                reservation: true,
                day_plan: true
            }
        });

        if (!slot) throw new Error(`TimeSlot ${timeSlotId} not found.`);

        let dayPlan = null;
        if (slot.day_plan) {
            const dayPlanId = slot.day_plan.id ?? slot.day_plan;

            dayPlan = await strapi.db.query('api::day-plan.day-plan').findOne({ where: { id: dayPlanId }, populate: ['week_agendum'] });
            if (dayPlan.dayType === 'day_off') {
                throw new Error('Cannot create reservation for a time slot on a day off.');
            }
        }

        const locked = await strapi.db.query('api::time-slot.time-slot').update({
            where: {
                id: timeSlotId,
                isActive: true
            },
            data: {
                isActive: false
            }

        });

        if (!locked) {
            throw new Error('Time slot is already reserved or inactive.');
        }

        // update agenda and day plan available slots
        let weekTotalActiveSlots = dayPlan?.week_agendum?.availableSlots || 0;
        let dayPlanActiveSlots = slot.day_plan?.availableSlots || 0;
        
        // confirmed reservations in this week
        const weekConfirmedReservations = await strapi.db.query('api::reservation.reservation').count({
            where: {
                statu: 'confirmed',
                time_slot: { day_plan: { week_agendum: { id: dayPlan?.week_agendum?.id } } }
            }
        });

        // confirmed reservations in this day plan
        const dayConfirmedReservations = await strapi.db.query('api::reservation.reservation').count({
            where: {
                statu: 'confirmed',
                time_slot: { day_plan: { id: slot.day_plan.id } }
            }
        });

        weekTotalActiveSlots = Math.max(weekTotalActiveSlots - 1, 0);
        dayPlanActiveSlots = Math.max(dayPlanActiveSlots - 1, 0);
        const WeekBusynessPercentage = weekTotalActiveSlots === 0 ? 0 : Math.round((weekConfirmedReservations / weekTotalActiveSlots) * 100);
        const DayBusynessPercentage = dayPlanActiveSlots === 0 ? 0 : Math.round((dayConfirmedReservations / dayPlanActiveSlots) * 100);

        await strapi.db.query('api::week-agenda.week-agenda').update({
            where: { id: dayPlan?.week_agendum?.id },
            data: { availableSlots: weekTotalActiveSlots, busyness: WeekBusynessPercentage }
        });

        await strapi.db.query('api::day-plan.day-plan').update({
            where: { id: slot.day_plan.id },
            data: { availableSlots: dayPlanActiveSlots, busyness: DayBusynessPercentage }
        });

        const reservation = await strapi.db.query('api::reservation.reservation').create({
            data: {
                time_slot: timeSlotId,
                player: playerProfile.id,
                terrain: terrainId,
                manager: campus.manager.id,
                type,
                notes: notes || '',
                statu: 'pending',       // awaits manager confirmation
                bookedAt: new Date(),
                publishedAt: new Date(),
            },
            populate: ['time_slot', 'player', 'terrain', 'manager']
        });

        return reservation;
    },

    
    async updateReservation(reservationId, userAuthId, updateData) {

        const playerProfile = await strapi.db.query('api::player.player').findOne({ where: { user: userAuthId } });

        const reservation = await strapi.db.query('api::reservation.reservation').findOne({
            where: {
                id: reservationId
            },
            populate: ['player']
        });

        if (!reservation) {
            throw new Error('Reservation not found.');
        }

        if (reservation.player.id !== playerProfile.id) {
            throw new Error('Unauthorized: You can only update your own reservations.');
        }

        if (reservation.statu === 'cancelled') {
            throw new Error('Cannot update a cancelled reservation.');
        }

        return await strapi.db.query('api::reservation.reservation').update({
            where: { id: reservationId },
            data: {
                type: updateData.type !== undefined ? updateData.type : reservation.type,
                notes: updateData.notes !== undefined ? updateData.notes : reservation.notes,
            },
            populate: ['time_slot', 'player', 'terrain', 'manager']
        });
    },

    
    async cancelReservation(reservationId, userAuthId) {

        const playerProfile = await strapi.db.query('api::player.player').findOne({ where: { user: userAuthId } });

        const reservation = await strapi.db.query('api::reservation.reservation').findOne({
            where: {
                id: reservationId
            },
            populate: ['player', 'time_slot']
        });

        if (!reservation) {
            throw new Error('Reservation not found.');
        }

        if (reservation.player.id !== playerProfile.id) {
            throw new Error('Unauthorized: You can only cancel your own reservations.');
        }

        if (reservation.statu === 'cancelled') {
            throw new Error('Reservation is already cancelled.');
        }

        await strapi.db.query('api::reservation.reservation').update({
            where: { id: reservationId },
            data: {
                statu: 'cancelled'
            },
            populate: ['time_slot', 'player', 'terrain', 'manager']
        });

        if (reservation.time_slot?.id) {
            await strapi.db.query('api::time-slot.time-slot').update({
                where: { id: reservation.time_slot.id },
                data: {
                    isActive: true
                }
            });
        }

        return { message: 'Reservation cancelled successfully.' };
    },

    // ── Manager methods ───────────────────────────────────────────────────

    
    async getManagerReservations(managerAuthId) {
        const managerProfile = await strapi.db.query('api::manager.manager').findOne({
            where: { user: managerAuthId }
        });
        if (!managerProfile) throw new Error('Manager profile not found');

        return await strapi.db.query('api::reservation.reservation').findMany({
            where: { manager: managerProfile.id },
            populate: ['time_slot.day_plan', 'terrain', 'player', 'manager'],
            orderBy: { bookedAt: 'desc' }
        });
    },

    // ── Employee methods ──────────────────────────────────────────────────

    
    async getEmployeeReservations(employeeAuthId) {
        const employeeProfile = await strapi.db.query('api::employee.employee').findOne({
            where: { User: employeeAuthId },
            populate: ['terrain']
        });
        if (!employeeProfile) throw new Error('Employee profile not found');
        if (!employeeProfile.terrain) throw new Error('No terrain assigned to this employee');

        return await strapi.db.query('api::reservation.reservation').findMany({
            where: { terrain: employeeProfile.terrain.id },
            populate: ['time_slot.day_plan', 'terrain', 'player', 'manager'],
            orderBy: { bookedAt: 'desc' }
        });
    },

    
    async getPendingReservations(managerAuthId) {
        const managerProfile = await strapi.db.query('api::manager.manager').findOne({
            where: { user: managerAuthId }
        });
        if (!managerProfile) throw new Error('Manager profile not found');

        return await strapi.db.query('api::reservation.reservation').findMany({
            where: { statu: 'pending', manager: managerProfile.id },
            populate: ['time_slot.day_plan', 'terrain', 'player', 'manager'],
            orderBy: { bookedAt: 'asc' }
        });
    },

    
    async confirmReservation(reservationId, managerAuthId) {
        const managerProfile = await strapi.db.query('api::manager.manager').findOne({
            where: { user: managerAuthId }
        });
        if (!managerProfile) throw new Error('Manager profile not found');

        const reservation = await strapi.db.query('api::reservation.reservation').findOne({
            where: { id: reservationId },
            populate: ['manager']
        });
        if (!reservation) throw new Error('Reservation not found');
        if (reservation.manager?.id !== managerProfile.id) throw new Error('Unauthorized');
        if (reservation.statu !== 'pending') throw new Error('Reservation is not pending');

        // Setting statu='confirmed' triggers afterUpdate lifecycle → creates conversation
        return await strapi.db.query('api::reservation.reservation').update({
            where: { id: reservationId },
            data: { statu: 'confirmed' },
            populate: ['time_slot.day_plan', 'terrain', 'player', 'manager']
        });
    },

    
    async denyReservation(reservationId, managerAuthId) {
        const managerProfile = await strapi.db.query('api::manager.manager').findOne({
            where: { user: managerAuthId }
        });
        if (!managerProfile) throw new Error('Manager profile not found');

        const reservation = await strapi.db.query('api::reservation.reservation').findOne({
            where: { id: reservationId },
            populate: ['manager', 'time_slot']
        });
        if (!reservation) throw new Error('Reservation not found');
        if (reservation.manager?.id !== managerProfile.id) throw new Error('Unauthorized');
        if (reservation.statu !== 'pending') throw new Error('Reservation is not pending');

        // Cancel the reservation and reactivate the time slot
        await strapi.db.query('api::reservation.reservation').update({
            where: { id: reservationId },
            data: { statu: 'cancelled' }
        });

        if (reservation.time_slot?.id) {
            await strapi.db.query('api::time-slot.time-slot').update({
                where: { id: reservation.time_slot.id },
                data: { isActive: true }
            });
        }

        return { message: 'Reservation denied.' };
    },

    // ── Player methods ────────────────────────────────────────────────────

    
    async getReservationsByPlayer(userAuthId) {
        const playerProfile = await strapi.db.query('api::player.player').findOne({ where: { user: userAuthId } });

        if (!playerProfile) {
            throw new Error('Player profile not found for the authenticated user.');
        }

        return await strapi.db.query('api::reservation.reservation').findMany({
            where: {
                player: playerProfile.id
            },
            populate: ['time_slot.day_plan', 'terrain', 'manager', 'player'],
            orderBy: { bookedAt: 'desc' }
        });
    }
}