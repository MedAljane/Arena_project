'use strict';
const service = require("../services/day-plan");


module.exports = {

    // @ts-ignore
    async create(ctx) {
        const { dayOfWeek, date, dayType, notes, week_agendum } = ctx.request.body;
        try {
            const dayPlan = await service.createDay({ dayOfWeek, date, dayType, notes, week_agendum });
            ctx.send(dayPlan);
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // @ts-ignore
    async getByDate(ctx) {
        const { date, campusId } = ctx.query;
        try {
            const dayPlans = await service.getByDate(date, campusId);
            ctx.send(dayPlans);
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // @ts-ignore
    async getById(ctx) {
        const { id } = ctx.params;
        try {
            const dayPlan = await service.getById(id);
            if (!dayPlan) {
                // @ts-ignore
                ctx.throw(404, 'Day plan not found');
            }
            ctx.send(dayPlan);
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // @ts-ignore
    async deleteDay(ctx) {
        const { id } = ctx.params;
        try {
            const result = await service.deleteDay(id);
            ctx.send(result);
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

}