'use strict';
const service = require("../services/day-plan");


module.exports = {

    
    async create(ctx) {
        const { dayOfWeek, date, dayType, notes, week_agendum } = ctx.request.body;
        try {
            const dayPlan = await service.createDay({ dayOfWeek, date, dayType, notes, week_agendum });
            ctx.send(dayPlan);
        } catch (error) {
            
            ctx.throw(400, error.message);
        }
    },

    
    async getByDate(ctx) {
        const { date, campusId } = ctx.query;
        try {
            const dayPlans = await service.getByDate(date, campusId);
            ctx.send(dayPlans);
        } catch (error) {
            
            ctx.throw(400, error.message);
        }
    },

    
    async getById(ctx) {
        const { id } = ctx.params;
        try {
            const dayPlan = await service.getById(id);
            if (!dayPlan) {
                
                ctx.throw(404, 'Day plan not found');
            }
            ctx.send(dayPlan);
        } catch (error) {
            
            ctx.throw(400, error.message);
        }
    },

    
    async deleteDay(ctx) {
        const { id } = ctx.params;
        try {
            const result = await service.deleteDay(id);
            ctx.send(result);
        } catch (error) {
            
            ctx.throw(400, error.message);
        }
    },

}