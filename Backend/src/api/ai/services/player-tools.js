'use strict';


const { tool } = require('ai');

const { z } = require('zod');

/**
 * Tool definitions for the PLAYER AI assistant.
 * Each tool wraps existing Strapi DB queries so the AI can search,
 * filter, and book on behalf of the authenticated player.
 *
 * @param {number} playerAuthId  - Strapi auth user ID of the player
 */
function buildPlayerTools(playerAuthId) {
    return {

        // ── Read tools ────────────────────────────────────────────────────

        getCampusesAndTerrains: tool({
            description:
                'List all campuses with their terrain types. Use this to discover what terrain types are available and in which campus.',
            parameters: z.object({}),
            execute: async () => {
                const campuses = await strapi.db
                    .query('api::campus.campus')
                    .findMany({ populate: { terrains: true } });

                return campuses.map((c) => ({
                    id:       c.id,
                    name:     c.Name,
                    address:  c.Address,
                    terrains: (c.terrains || []).map((t) => ({
                        id:   t.id,
                        type: t.Type,
                    })),
                }));
            },
        }),

        getAvailableSlotsForDate: tool({
            description:
                'Get available (unbooked) time slots for a specific terrain type on a given date. ' +
                'Returns slots grouped by campus so the player can choose.',
            parameters: z.object({
                date:              z.string().describe('Date in YYYY-MM-DD format'),
                terrainType:       z.string().describe('Terrain type: Football, Basketball, Paddel, Tennis'),
                preferredStartHour: z
                    .number()
                    .optional()
                    .describe('Preferred earliest start hour (0-23, e.g. 15 for 3 PM)'),
                preferredEndHour: z
                    .number()
                    .optional()
                    .describe('Preferred latest end hour (0-23, e.g. 19 for 7 PM)'),
            }),
            execute: async ({ date, terrainType, preferredStartHour, preferredEndHour }) => {
                // Find all day plans for this date that are not day_off
                const dayPlans = await strapi.db.query('api::day-plan.day-plan').findMany({
                    where: {
                        date,
                        dayType: { $ne: 'day_off' },
                        week_agendum: {
                            statu: 'Published',
                            terrain: { Type: terrainType },
                        },
                    },
                    populate: {
                        time_slots: { where: { isActive: true } },
                        week_agendum: {
                            populate: { terrain: true, campus: true },
                        },
                    },
                });

                const results = [];
                for (const dp of dayPlans) {
                    const campus  = dp.week_agendum?.campus;
                    const terrain = dp.week_agendum?.terrain;
                    let slots     = dp.time_slots || [];

                    // Filter by preferred time window if provided
                    if (preferredStartHour !== undefined || preferredEndHour !== undefined) {
                        slots = slots.filter((s) => {
                            const startH = parseInt(s.startTime?.split(':')[0] || '0', 10);
                            const ok =
                                (preferredStartHour === undefined || startH >= preferredStartHour) &&
                                (preferredEndHour   === undefined || startH <  preferredEndHour);
                            return ok;
                        });
                    }

                    if (slots.length > 0) {
                        results.push({
                            campusId:   campus?.id,
                            campusName: campus?.Name,
                            address:    campus?.Address,
                            terrainId:  terrain?.id,
                            terrainType: terrain?.Type,
                            slots: slots.map((s) => ({
                                id:        s.id,
                                startTime: s.startTime,
                                endTime:   s.endTime,
                            })),
                        });
                    }
                }
                return results;
            },
        }),

        getMyReservations: tool({
            description: "Retrieve the current player's upcoming and past reservations.",
            parameters: z.object({}),
            execute: async () => {
                const profile = await strapi.db
                    .query('api::player.player')
                    .findOne({ where: { user: playerAuthId } });

                if (!profile) return { error: 'Player profile not found' };

                const reservations = await strapi.db
                    .query('api::reservation.reservation')
                    .findMany({
                        where: { player: profile.id },
                        populate: ['time_slot.day_plan', 'terrain', 'manager'],
                        orderBy: { bookedAt: 'desc' },
                    });

                return reservations.map((r) => ({
                    id:        r.id,
                    status:    r.statu,
                    type:      r.type,
                    terrain:   r.terrain?.Type,
                    bookedAt:  r.bookedAt,
                    timeSlot: r.time_slot
                        ? {
                              start: r.time_slot.startTime,
                              end:   r.time_slot.endTime,
                              date:  r.time_slot.day_plan?.date,
                          }
                        : null,
                }));
            },
        }),

        // ── Write tools ───────────────────────────────────────────────────

        bookReservation: tool({
            description:
                'Book a time slot for the player. Requires the slot ID, campus ID, and terrain ID ' +
                'obtained from getAvailableSlotsForDate.',
            parameters: z.object({
                timeSlotId: z.number().describe('ID of the time slot to book'),
                campusId:   z.number().describe('ID of the campus'),
                terrainId:  z.number().describe('ID of the terrain'),
                type:       z
                    .enum(['normal', 'urgent'])
                    .default('normal')
                    .describe('Reservation type'),
                notes: z.string().optional().describe('Optional notes for the manager'),
            }),
            execute: async ({ timeSlotId, campusId, terrainId, type, notes }) => {
                const reservationService = require('../../reservation/services/reservation');
                try {
                    const result = await reservationService.createReservation({
                        userAuthId: playerAuthId,
                        timeSlotId,
                        campusId,
                        terrainId,
                        type,
                        notes: notes || '',
                    });
                    return {
                        success:       true,
                        reservationId: result.id,
                        status:        result.statu,
                        message:       'Reservation created successfully. It is pending manager confirmation.',
                    };
                } catch (err) {
                    return { success: false, error: err.message };
                }
            },
        }),

        cancelReservation: tool({
            description: "Cancel one of the player's existing reservations.",
            parameters: z.object({
                reservationId: z.number().describe('ID of the reservation to cancel'),
            }),
            execute: async ({ reservationId }) => {
                const reservationService = require('../../reservation/services/reservation');
                try {
                    await reservationService.cancelReservation(reservationId, playerAuthId);
                    return { success: true, message: 'Reservation cancelled successfully.' };
                } catch (err) {
                    return { success: false, error: err.message };
                }
            },
        }),
    };
}

module.exports = { buildPlayerTools };
