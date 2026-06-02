'use strict';

const weekAgendaService = require('../services/week-agenda');

module.exports = {

    // @ts-ignore
    async create(ctx){
        const managerId = ctx.state.user.id;
        const { weekStartDate, campusId, terrainId } = ctx.request.body;
        
        try {
            const agenda = await weekAgendaService.createWeekAgenda({ weekStartDate, campusId, managerId, terrainId });
            ctx.send({
                message: `Week agenda for week starting on ${agenda.weekStartDate} created successfully`,
                agenda
            });
        } catch (err) {
            console.error("Error in createWeekAgendaController:", err);
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    },

    // @ts-ignore
    async publish(ctx){
        const { id } = ctx.params;

        try {
            const agenda = await weekAgendaService.publishWeekAgenda(id);
            ctx.send({
                message: `Week agenda with ID ${id} published successfully`,
                agenda
            });
        } catch (err) {
            console.error("Error in publishWeekAgendaController:", err);
            // @ts-ignore
            ctx.badRequest(err.message);
        }
     },

     // @ts-ignore
     async getAvailableSlots(ctx) {
        const { campusId, terrainId, date } = ctx.query;

        try {
            const slots = await weekAgendaService.getAvailableSlots(campusId, terrainId, date);
            ctx.send({
                message: `Available slots for ${date} retrieved successfully`,
                slots
            });
        } catch (err) {
            console.error("Error in getAvailableSlotsController:", err);
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    },

    // @ts-ignore
    async getTerrainAgenda(ctx) {
        const { campusId, terrainId } = ctx.query;

        try {
            const agenda = await weekAgendaService.getTerrainAgenda(campusId, terrainId);
            ctx.send({
                message: `Week agenda for campus ${campusId} and terrain ${terrainId} retrieved successfully`,
                agenda
            });
        } catch (err) {
            console.error("Error in getTerrainAgendaController:", err);
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    },

    // @ts-ignore
    async getAll(ctx) {
        try {
            const agendas = await weekAgendaService.getAllAgendas();
            ctx.send({ agendas });
        } catch (err) {
            console.error('Error in getAll week-agenda controller:', err);
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    },

    // @ts-ignore
    async getById(ctx) {
        const { id } = ctx.params;

        const agenda = await strapi.db.query('api::week-agenda.week-agenda').findOne({
            where: { id },
            populate: {
                campus:    true,
                terrain:   true,
                day_plans: { populate: ['time_slots'] },
            },
        });

        if (!agenda) {
            // @ts-ignore
            ctx.notFound(`Week agenda with ID ${id} not found`);
            return;
        }

        ctx.send({
            message: `Week agenda with ID ${id} retrieved successfully`,
            agenda
        });
    },

    // @ts-ignore
    async deleteAgenda(ctx) {
        const { id } = ctx.params;

        try {
            const result = await weekAgendaService.deleteWeekAgenda(id);
            ctx.send({
                message: `Week agenda with ID ${id} deleted successfully`,
                result
            });
        } catch (err) {
            console.error("Error in deleteWeekAgendaController:", err);
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    },

}