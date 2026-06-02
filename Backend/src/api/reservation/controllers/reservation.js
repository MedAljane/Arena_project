'use strict';

const reservationService = require("../services/reservation");

module.exports = {

    // @ts-ignore
    async create(ctx) {
        const userAuthId = ctx.state.user.id;
        const { timeSlotId, campusId, terrainId, type, notes } = ctx.request.body;

        try {
            const reservation = await reservationService.createReservation({
                userAuthId: userAuthId,
                timeSlotId,
                campusId,
                terrainId,
                type,
                notes
            });

            ctx.send({ data: reservation });
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // @ts-ignore
    async update(ctx) {
        const reservationId = ctx.params.id;
        const userauthId = ctx.state.user.id;
        const data = ctx.request.body.data;

        try {
            const updated = await reservationService.updateReservation(reservationId, userauthId, data);
            ctx.send({data: updated})
        } catch (error){
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // @ts-ignore
    async cancel(ctx) {
        const reservationId = ctx.params.id;
        const userauthId = ctx.state.user.id;

        try {
            const updated = await reservationService.cancelReservation(reservationId, userauthId);
            ctx.send({data: updated})
        } catch (error){
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // @ts-ignore
    async getReservationsByPlayer(ctx) {
        const userauthId = ctx.state.user.id;
        try {
            const reservations = await reservationService.getReservationsByPlayer(userauthId);
            ctx.send({ data: reservations });
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // ── Employee handlers ─────────────────────────────────────────────────

    // @ts-ignore
    async getEmployeeReservations(ctx) {
        const employeeAuthId = ctx.state.user.id;
        try {
            const reservations = await reservationService.getEmployeeReservations(employeeAuthId);
            ctx.send({ data: reservations });
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // ── Manager handlers ──────────────────────────────────────────────────

    // @ts-ignore
    async getManagerReservations(ctx) {
        const managerAuthId = ctx.state.user.id;
        try {
            const reservations = await reservationService.getManagerReservations(managerAuthId);
            ctx.send({ data: reservations });
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // @ts-ignore
    async getPendingReservations(ctx) {
        const managerAuthId = ctx.state.user.id;
        try {
            const reservations = await reservationService.getPendingReservations(managerAuthId);
            ctx.send({ data: reservations });
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // @ts-ignore
    async confirmReservation(ctx) {
        const { id } = ctx.params;
        const managerAuthId = ctx.state.user.id;
        try {
            const result = await reservationService.confirmReservation(id, managerAuthId);
            ctx.send({ data: result });
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

    // @ts-ignore
    async denyReservation(ctx) {
        const { id } = ctx.params;
        const managerAuthId = ctx.state.user.id;
        try {
            const result = await reservationService.denyReservation(id, managerAuthId);
            ctx.send({ data: result });
        } catch (error) {
            // @ts-ignore
            ctx.throw(400, error.message);
        }
    },

};