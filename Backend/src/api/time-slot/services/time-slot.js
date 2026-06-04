'use strict';

const { publish } = require("../../week-agenda/controllers/week-agenda");

module.exports = {

    
    async checkDuplicate(dayPlanId, startTime, endTime, excludeId = null) {
        const where = {
            day_plan: { id: parseInt(dayPlanId) },
            startTime: startTime,
            endTime: endTime,
        };

        if (excludeId) {
            
            where.id = { $ne: parseInt(excludeId) };
        }

        const existingTimeSlot = await strapi.query('api::time-slot.time-slot').findOne({ where });

        if (existingTimeSlot) {
            throw new Error('A time slot with the same day plan, start time, and end time already exists.');
        }

    },

    
    async createSlot(data) {
        await this.checkDuplicate(data.day_plan, data.start_time, data.end_time);
        return await strapi.db.query('api::time-slot.time-slot').create({
            data: {
                day_plan: data.day_plan,
                startTime: data.start_time,
                endTime: data.end_time,
                isActive: true,
                publishedAt: new Date(),
            },
            populate: ['day_plan', 'reservation'],
        });
    },

    
    async updateSlot(id, data) {

        if (data.startTime || data.endTime) {
            const current = await strapi.db.query('api::time-slot.time-slot').findOne({ where: { id }, populate: ['day_plan'] });

            const dayPlanId = data.day_plan ?? current.day_plan?.id;
            const startTime = data.start_time ?? current.start_time;
            const endTime = data.end_time ?? current.end_time;

            await this.checkDuplicate(dayPlanId, startTime, endTime, id);
        }

        return await strapi.db.query('api::time-slot.time-slot').update({
            where: { id },
            data,
            populate: ['day_plan', 'reservation'],
        });
    },

    
    async deleteSlot(id){
        return await strapi.db.query('api::time-slot.time-slot').delete({
            where: { id },
            populate: ['day_plan', 'reservation'],
        });
    },

    
    async getTimeSlots(filters) {
        const where = {};

        if (filters.day_plan) {
            where.day_plan = { id: parseInt(filters.day_plan) };
        }

        if (filters.isActive !== undefined) {
            where.isActive = filters.isActive === 'true';
        }

        return await strapi.db.query('api::time-slot.time-slot').findMany({
            where,
            populate: ['day_plan', 'reservation'],
        });
    },


};