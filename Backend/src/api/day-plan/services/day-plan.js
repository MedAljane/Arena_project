'use strict';

module.exports = {

    // @ts-ignore
    async createDay(data) {
        return await strapi.db.query('api::day-plan.day-plan').create({
            data: {
                ...data,
                publishedAt: new Date(),
            },
            populate: ['week_agendum', 'time_slots']
        });
    },

    // @ts-ignore
    async getByDate(date, campusId) {
        return await strapi.db.query('api::day-plan.day-plan').findMany({
            where: {
                date,
                week_agendum: {
                    campus: { id: campusId }
                }
            },
            populate: ['week_agendum', 'time_slots']
        });

    },

    // @ts-ignore
    async getById(id) {
        return await strapi.db.query('api::day-plan.day-plan').findOne({
            where: { id },
            populate: ['week_agendum', 'time_slots']
        });
    },

    // @ts-ignore
    async deleteDay(id) {
        await strapi.db.query('api::day-plan.day-plan').delete({ where: { id } });

        // Optionally, also delete associated time slots if they exist
        await strapi.db.query('api::time-slot.time-slot').delete({ where: { day_plan: id } });

        return { message: 'Day plan and associated time slots deleted successfully' };
    },

}