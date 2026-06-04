'use strict';


const { tool } = require('ai');

const { z } = require('zod');

/**
 * Tool definitions for the MANAGER AI assistant.
 *
 * @param {number} managerAuthId - Strapi auth user ID of the manager
 */
function buildManagerTools(managerAuthId) {
    return {

        // ── Read tools ────────────────────────────────────────────────────

        getMyTerrains: tool({
            description: "Get all terrains belonging to the manager's campuses.",
            parameters: z.object({}),
            execute: async () => {
                const managerProfile = await strapi.db
                    .query('api::manager.manager')
                    .findOne({ where: { user: managerAuthId } });
                if (!managerProfile) return { error: 'Manager profile not found' };

                const terrains = await strapi.db.query('api::terrain.terrain').findMany({
                    where: { campus: { manager: managerProfile.id } },
                    populate: { campus: true, week_agenda: true },
                });

                return terrains.map((t) => ({
                    id:         t.id,
                    type:       t.Type,
                    campusId:   t.campus?.id,
                    campusName: t.campus?.Name,
                    agendaCount: (t.week_agenda || []).length,
                }));
            },
        }),

        getAgendaDetails: tool({
            description:
                'Get the full details of a week agenda including all day plans and their time slots.',
            parameters: z.object({
                agendaId: z.number().describe('ID of the week agenda'),
            }),
            execute: async ({ agendaId }) => {
                const agenda = await strapi.db
                    .query('api::week-agenda.week-agenda')
                    .findOne({
                        where: { id: agendaId },
                        populate: {
                            campus:    true,
                            terrain:   true,
                            day_plans: { populate: ['time_slots'] },
                        },
                    });
                if (!agenda) return { error: 'Agenda not found' };

                return {
                    id:            agenda.id,
                    weekStartDate: agenda.weekStartDate,
                    statu:         agenda.statu,
                    campusName:    agenda.campus?.Name,
                    terrainType:   agenda.terrain?.Type,
                    dayPlans: (agenda.day_plans || []).map((dp) => ({
                        id:        dp.id,
                        dayOfWeek: dp.dayOfWeek,
                        date:      dp.date,
                        dayType:   dp.dayType,
                        timeSlots: (dp.time_slots || []).map((s) => ({
                            id:        s.id,
                            startTime: s.startTime,
                            endTime:   s.endTime,
                            isActive:  s.isActive,
                        })),
                    })),
                };
            },
        }),

        getPendingReservations: tool({
            description: "Get all pending (unconfirmed) reservations for the manager's campus.",
            parameters: z.object({}),
            execute: async () => {
                const reservationService = require('../../reservation/services/reservation');
                try {
                    const list = await reservationService.getPendingReservations(managerAuthId);
                    return list.map((r) => ({
                        id:          r.id,
                        playerName:  r.player?.nom || `Player #${r.player?.id}`,
                        terrainType: r.terrain?.Type,
                        timeSlot:    r.time_slot
                            ? { start: r.time_slot.startTime, end: r.time_slot.endTime }
                            : null,
                        date:        r.time_slot?.day_plan?.date,
                        bookedAt:    r.bookedAt,
                    }));
                } catch (err) {
                    return { error: err.message };
                }
            },
        }),

        // ── Agenda write tools ────────────────────────────────────────────

        createWeekAgenda: tool({
            description:
                'Create a new week agenda for a specific terrain starting on a Monday. ' +
                'Auto-generates 7 day plans with default time slots (Mon-Tue are day_off by default).',
            parameters: z.object({
                weekStartDate: z
                    .string()
                    .describe('Start date of the week in YYYY-MM-DD format (must be a Monday)'),
                terrainId: z.number().describe('ID of the terrain'),
                campusId:  z.number().describe('ID of the campus'),
            }),
            execute: async ({ weekStartDate, terrainId, campusId }) => {
                const weekAgendaService = require('../../week-agenda/services/week-agenda');
                try {
                    const agenda = await weekAgendaService.createWeekAgenda({
                        weekStartDate,
                        campusId,
                        managerId:  managerAuthId,
                        terrainId,
                    });
                    return {
                        success:       true,
                        agendaId:      agenda.id,
                        weekStartDate: agenda.weekStartDate,
                        dayPlansCount: (agenda.day_plans || []).length,
                        message:       `Week agenda created for week of ${weekStartDate}.`,
                    };
                } catch (err) {
                    return { success: false, error: err.message };
                }
            },
        }),

        publishAgenda: tool({
            description:
                'Publish a week agenda so players can see it and book slots. ' +
                'Only publish after cleaning up day_off slots.',
            parameters: z.object({
                agendaId: z.number().describe('ID of the agenda to publish'),
            }),
            execute: async ({ agendaId }) => {
                const weekAgendaService = require('../../week-agenda/services/week-agenda');
                try {
                    await weekAgendaService.publishWeekAgenda(agendaId);
                    return { success: true, message: `Agenda #${agendaId} published successfully.` };
                } catch (err) {
                    return { success: false, error: err.message };
                }
            },
        }),

        deleteAgenda: tool({
            description: 'Delete a week agenda and all its day plans and time slots.',
            parameters: z.object({
                agendaId: z.number().describe('ID of the agenda to delete'),
            }),
            execute: async ({ agendaId }) => {
                const weekAgendaService = require('../../week-agenda/services/week-agenda');
                try {
                    await weekAgendaService.deleteWeekAgenda(agendaId);
                    return { success: true, message: `Agenda #${agendaId} deleted.` };
                } catch (err) {
                    return { success: false, error: err.message };
                }
            },
        }),

        // ── Day plan tools ────────────────────────────────────────────────

        setDayPlanType: tool({
            description:
                'Change the type of a day plan (normal / urgent_only / day_off). ' +
                "Set to 'day_off' to mark a day as closed. " +
                'After setting a day to day_off you should delete its time slots.',
            parameters: z.object({
                dayPlanId: z.number().describe('ID of the day plan'),
                dayType: z
                    .enum(['normal', 'urgent_only', 'day_off'])
                    .describe('New day type'),
            }),
            execute: async ({ dayPlanId, dayType }) => {
                await strapi.db.query('api::day-plan.day-plan').update({
                    where: { id: dayPlanId },
                    data:  { dayType },
                });
                return { success: true, message: `Day plan #${dayPlanId} set to ${dayType}.` };
            },
        }),

        // ── Time slot tools ───────────────────────────────────────────────

        deleteTimeSlot: tool({
            description:
                'Delete a specific time slot. Use this to clean up slots on day_off days.',
            parameters: z.object({
                slotId: z.number().describe('ID of the time slot to delete'),
            }),
            execute: async ({ slotId }) => {
                const existing = await strapi.db
                    .query('api::time-slot.time-slot')
                    .findOne({ where: { id: slotId } });
                if (!existing) return { success: false, error: 'Slot not found' };

                await strapi.db.query('api::time-slot.time-slot').delete({ where: { id: slotId } });
                return { success: true, message: `Time slot #${slotId} deleted.` };
            },
        }),

        createTimeSlot: tool({
            description:
                'Create a new time slot in a day plan. Times must be in HH:MM format (e.g. 14:00).',
            parameters: z.object({
                dayPlanId: z.number().describe('ID of the day plan'),
                startTime: z.string().describe('Start time HH:MM'),
                endTime:   z.string().describe('End time HH:MM'),
            }),
            execute: async ({ dayPlanId, startTime, endTime }) => {
                const existing = await strapi.db.query('api::time-slot.time-slot').findOne({
                    where: { day_plan: dayPlanId, startTime, endTime },
                });
                if (existing) {
                    return { success: false, error: 'A slot with the same time already exists.' };
                }
                const slot = await strapi.db.query('api::time-slot.time-slot').create({
                    data: {
                        day_plan:    dayPlanId,
                        startTime,
                        endTime,
                        isActive:    true,
                        publishedAt: new Date(),
                    },
                });
                return { success: true, slotId: slot.id, message: `Slot ${startTime}–${endTime} created.` };
            },
        }),

        // ── Reservation tools ─────────────────────────────────────────────

        confirmReservation: tool({
            description: 'Confirm a pending reservation. This notifies the player and creates a chat.',
            parameters: z.object({
                reservationId: z.number().describe('ID of the reservation to confirm'),
            }),
            execute: async ({ reservationId }) => {
                const reservationService = require('../../reservation/services/reservation');
                try {
                    await reservationService.confirmReservation(reservationId, managerAuthId);
                    return { success: true, message: `Reservation #${reservationId} confirmed.` };
                } catch (err) {
                    return { success: false, error: err.message };
                }
            },
        }),

        cancelReservation: tool({
            description:
                'Cancel (deny) a reservation regardless of its current status. ' +
                'The time slot is freed and the reservation is marked as cancelled. ' +
                'Use this when the manager explicitly asks to cancel a booking.',
            parameters: z.object({
                reservationId: z.number().describe('ID of the reservation to cancel'),
            }),
            execute: async ({ reservationId }) => {
                const reservationService = require('../../reservation/services/reservation');
                try {
                    // If still pending, use denyReservation; if confirmed, cancel directly.
                    const res = await strapi.db.query('api::reservation.reservation').findOne({
                        where: { id: reservationId },
                        populate: ['manager', 'time_slot'],
                    });
                    if (!res) return { success: false, error: 'Reservation not found.' };

                    if (res.statu === 'pending') {
                        await reservationService.denyReservation(reservationId, managerAuthId);
                    } else if (res.statu === 'confirmed') {
                        // Cancel and reactivate the slot
                        await strapi.db.query('api::reservation.reservation').update({
                            where: { id: reservationId },
                            data:  { statu: 'cancelled' },
                        });
                        if (res.time_slot?.id) {
                            await strapi.db.query('api::time-slot.time-slot').update({
                                where: { id: res.time_slot.id },
                                data:  { isActive: true },
                            });
                        }
                    } else {
                        return { success: false, error: `Reservation is already ${res.statu}.` };
                    }
                    return {
                        success: true,
                        message: `Reservation #${reservationId} cancelled. Time slot is available again.`,
                    };
                } catch (err) {
                    return { success: false, error: err.message };
                }
            },
        }),

        getReservationById: tool({
            description:
                'Look up a single reservation by its numeric ID. ' +
                'Returns full details: player, terrain, time slot, status, date, notes.',
            parameters: z.object({
                reservationId: z.number().describe('ID of the reservation to look up'),
            }),
            execute: async ({ reservationId }) => {
                const res = await strapi.db.query('api::reservation.reservation').findOne({
                    where:   { id: reservationId },
                    populate: ['time_slot.day_plan', 'terrain', 'player', 'manager'],
                });
                if (!res) return { error: `Reservation #${reservationId} not found.` };
                return {
                    id:          res.id,
                    status:      res.statu,
                    type:        res.type,
                    notes:       res.notes,
                    bookedAt:    res.bookedAt,
                    terrainType: res.terrain?.Type,
                    player:      res.player?.nom || `Player #${res.player?.id}`,
                    timeSlot: res.time_slot ? {
                        start: res.time_slot.startTime,
                        end:   res.time_slot.endTime,
                        date:  res.time_slot.day_plan?.date,
                        day:   res.time_slot.day_plan?.dayOfWeek,
                    } : null,
                };
            },
        }),

        getReservationsByDate: tool({
            description:
                'List all reservations for the manager\'s campus on a specific date. ' +
                'Useful to see the full schedule for a given day.',
            parameters: z.object({
                date: z.string().describe('Date in YYYY-MM-DD format'),
                status: z
                    .enum(['all', 'pending', 'confirmed', 'cancelled'])
                    .default('all')
                    .describe('Filter by reservation status (default: all)'),
            }),
            execute: async ({ date, status }) => {
                const managerProfile = await strapi.db.query('api::manager.manager').findOne({
                    where: { user: managerAuthId },
                });
                if (!managerProfile) return { error: 'Manager profile not found' };

                const where = {
                    time_slot: { day_plan: { date } },
                    terrain:   { campus: { manager: managerProfile.id } },
                };
                if (status !== 'all') where.statu = status;

                const reservations = await strapi.db.query('api::reservation.reservation').findMany({
                    where,
                    populate: ['time_slot.day_plan', 'terrain', 'player'],
                    orderBy:  { bookedAt: 'asc' },
                });

                if (reservations.length === 0) {
                    return { date, found: 0, message: `No ${status === 'all' ? '' : status + ' '}reservations found for ${date}.` };
                }

                return {
                    date,
                    found: reservations.length,
                    reservations: reservations.map((r) => ({
                        id:          r.id,
                        status:      r.statu,
                        type:        r.type,
                        terrainType: r.terrain?.Type,
                        player:      r.player?.nom || `Player #${r.player?.id}`,
                        timeSlot: r.time_slot ? {
                            start: r.time_slot.startTime,
                            end:   r.time_slot.endTime,
                        } : null,
                        notes: r.notes || null,
                    })),
                };
            },
        }),
    };
}

module.exports = { buildManagerTools };

module.exports = { buildManagerTools };
