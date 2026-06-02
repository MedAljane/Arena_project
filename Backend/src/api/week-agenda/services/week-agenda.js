'use strict';

const reservation = require("../../reservation/controllers/reservation");

const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

// @ts-ignore
function dateOfDay(weekStartDate, index) {
    const date = new Date(weekStartDate);
    date.setDate(date.getDate() + index);
    return date.toISOString().split('T')[0];
}

module.exports = {

    // @ts-ignore
    async createWeekAgenda({ weekStartDate, campusId, managerId, terrainId }) {
        const manager = await strapi.db.query('api::manager.manager').findOne({ where: { user: managerId } });
        if (!manager) {
            throw new Error('Manager profile not found');
        }

        const campus = await strapi.db.query('api::campus.campus').findOne({ where: { id: campusId, manager: manager.id } });
        if (!campus) {
            throw new Error('Campus not found or you do not have permission to manage it');
        }

        const terrain = await strapi.db.query('api::terrain.terrain').findOne({ where: { id: terrainId, campus: campus.id } });
        if (!terrain) {
            throw new Error('Terrain not found');
        }

        const agenda = await strapi.db.query('api::week-agenda.week-agenda').create({
            data: {
                weekStartDate,
                statu: 'Draft',
                campus: campus.id,
                terrain: terrain.id,
                busyness: 0,
            },
            populate: ['campus', 'terrain']
        });

        const dayPlansCreated = [];

        let totalweekSlots = 0;

        for (let i = 0; i < 7; i++) {
            const day = days[i];
            const isDayOff = (i === 0 || i === 1);
            const dayPlan = await strapi.db.query('api::day-plan.day-plan').create({
                data: {
                    dayOfWeek: day,
                    date: dateOfDay(weekStartDate, i),
                    dayType: isDayOff ? 'day_off' : 'normal',
                    notes: '',
                    week_agendum: agenda.id,
                    busyness: 0,
                    publishedAt: new Date(),
                },
                populate: ['week_agendum']
            });
            // build default slots
            const defaultSlots = [
                ['14:00', '16:00'],
                ['16:00', '18:00'],
                ['18:00', '20:00'],
                ['20:00', '22:00'],
            ];

            if (day === 'Saturday' || day === 'Sunday') {
                defaultSlots.unshift(['10:00', '12:00'], ['12:00', '14:00']);
            }

            let availableSlots = 0;
            // create slots (concurrent)
            await Promise.all(defaultSlots.map(([startTime, endTime]) =>{
                strapi.db.query('api::time-slot.time-slot').create({
                    data: {
                        startTime,
                        endTime,
                        isActive: true,
                        day_plan: dayPlan.id,
                    },
                });
                availableSlots++;
            }
            ));

            await strapi.db.query('api::day-plan.day-plan').update({
                where: { id: dayPlan.id },
                data: { availableSlots: availableSlots, totalSlots: availableSlots }
            });

            dayPlansCreated.push(dayPlan);
            totalweekSlots += availableSlots;
        }

        await strapi.db.query('api::week-agenda.week-agenda').update({
            where: { id: agenda.id },
            data: { totalSlots: totalweekSlots, availableSlots: totalweekSlots }
        });

        return await strapi.db.query('api::week-agenda.week-agenda').findOne({ where: { id: agenda.id }, populate: ['campus', 'terrain', 'day_plans'] });
    },

    // @ts-ignore
    async publishWeekAgenda(id) {
        const agenda = await strapi.db.query('api::week-agenda.week-agenda').findOne({ where: { id } });

        if (!agenda) {
            throw new Error('Week agenda not found');
        }

        if (agenda.statu === 'Published') {
            throw new Error('Week agenda is already published');
        }

        await strapi.db.query('api::week-agenda.week-agenda').update({
            where: { id },
            data: { statu: 'Published', publishedAt: new Date() },
            populate: ['campus', 'terrain', 'day_plans']
        });

        return true;
    },

    // @ts-ignore
    async getAvailableSlots(campusId, terrainId, date) {

        const dayPlans = await strapi.db.query('api::day-plan.day-plan').findMany({
            where: {
                date,
                dayType: 'normal',
                week_agendum: {
                    statu: 'Published',
                    campus: { id: campusId },
                    terrain: { id: terrainId }
                }
            },
            populate: {
                time_slots: {
                    where: { isActive: true },
                    populate: { reservation: true }
                },
                weekAgendum: {
                    populate: ['campus', 'terrain']
                }

            }
        });

        return dayPlans;
    },

    // @ts-ignore
    async getTerrainAgenda(campusId, terrainId) {
        const agenda = await strapi.db.query('api::week-agenda.week-agenda').findOne({
            where: {
                campus: { id: campusId },
                terrain: { id: terrainId }
            },
            populate: {
                campus: true,
                terrain: true,
                day_plans: { populate: ['time_slots'] }
            }
        });
        return agenda;
    },

    // @ts-ignore
    async getAllAgendas() {
        return await strapi.db.query('api::week-agenda.week-agenda').findMany({
            populate: ['campus', 'terrain', 'day_plans'],
            orderBy: { weekStartDate: 'desc' },
        });
    },

    // @ts-ignore
    async getAgendas(campusId) {
        const agendas = await strapi.db.query('api::week-agenda.week-agenda').findMany({
            where: {
                campus: { id: campusId },
            },
            populate: {
                campus: true,
                terrain: true,
                day_plans: { populate: ['time_slots'] }
            }
        });
        return agendas;
    },

    // @ts-ignore
    async deleteWeekAgenda(id) {
        const agenda = await strapi.db.query('api::week-agenda.week-agenda').findOne({ where: { id }, populate: ['day_plans'] });
        if (!agenda) {
            throw new Error('Week agenda not found');
        }

        // delete associated day plans and their time slots
        await Promise.all(agenda.day_plans.map(async (dayPlan) => {
            await strapi.db.query('api::time-slot.time-slot').deleteMany({ where: { day_plan: dayPlan.id } });
            await strapi.db.query('api::day-plan.day-plan').delete({ where: { id: dayPlan.id } });
        }));

        await strapi.db.query('api::week-agenda.week-agenda').delete({ where: { id } });
        return { message: `Week agenda ${id} deleted` };
    },
};