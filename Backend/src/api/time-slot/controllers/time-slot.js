'use strict';

const service = require('../services/time-slot');

module.exports = {

    
    async create(ctx) {
        try {
            const data = ctx.request.body.data;
            if (!data.day_plan || isNaN(parseInt(data.day_plan))) {
                return ctx.badRequest('day_plan is required and must be a valid ID.');
            }

            const dayPlan = await strapi.db.query('api::day-plan.day-plan').findOne({ where: { id: parseInt(data.day_plan) } });
            if (!dayPlan) {
                return ctx.badRequest('The specified day_plan does not exist.');
            }

            if (dayPlan.dayType === 'day_off') {
                return ctx.badRequest('Cannot create time slots for a day off.');
            }

            data.day_plan = parseInt(data.day_plan);

            const result = await service.createSlot(
                data
            );

            ctx.send({ data: result });
        } catch (error) {
            
            ctx.badRequest(error.message);
        }
    },

    
    async update(ctx) {
        const id = ctx.params.id;

        try {
            const result = await service.updateSlot(id, ctx.request.body.data);
            ctx.send({ data: result });
        } catch (error) {
            
            ctx.badRequest(error.message);
        }
    },

    
    async delete(ctx) {
        const id = ctx.params.id;

        const existing = await strapi.db.query('api::time-slot.time-slot').findOne({ where: { id } });

        if (!existing) {
            return ctx.notFound('Time slot not found');
        }

        await strapi.db.query('api::time-slot.time-slot').delete({ where: { id } });

        ctx.send({ message: 'Time slot deleted successfully' });
    },

    
    async getTimeSlots(ctx) {
        try {
            const filters = ctx.query;
            const result = await service.getTimeSlots(filters);
            ctx.send({ data: result });
        } catch (error) {
            
            ctx.badRequest(error.message);
        }
    },

};