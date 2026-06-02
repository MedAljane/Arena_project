'use strict';

const playerService = require('../services/player');

module.exports = {

    // ── Self-service ──────────────────────────────────────────────────────────

    async getMe(ctx) {
        try {
            const profile = await playerService.getPlayerProfile(ctx.state.user.id);
            ctx.send(profile);
        } catch (err) {
            console.error('Error in getMe (player) controller:', err);
            ctx.badRequest(err.message);
        }
    },

    async updateMe(ctx) {
        try {
            const { username, email, address, phone } = ctx.request.body;
            const profile = await playerService.updatePlayerProfile(ctx.state.user.id, { username, email, address, phone });
            ctx.send({ message: 'Profile updated successfully', profile });
        } catch (err) {
            console.error('Error in updateMe (player) controller:', err);
            ctx.badRequest(err.message);
        }
    },

    // ── Admin management ──────────────────────────────────────────────────────

    async registerPlayer(ctx) {
        try {
            const { username, email, password, address, phone } = ctx.request.body;
            const { user } = await playerService.registerPlayer({ username, email, password, address, phone });
            ctx.send({ message: `Player ${user.username} registered successfully`, user });
        } catch (err) {
            console.error('Error in registerPlayer controller:', err);
            ctx.badRequest(err.message);
        }
    },

    async updatePlayer(ctx) {
        try {
            const { id } = ctx.params;
            const { username, email, address, phone } = ctx.request.body;
            const user = await playerService.updatePlayer(id, { username, email, address, phone });
            ctx.send({ message: `Player updated successfully`, user });
        } catch (err) {
            console.error('Error in updatePlayer controller:', err);
            ctx.badRequest(err.message);
        }
    },

    async deletePlayer(ctx) {
        try {
            const { id } = ctx.params;
            const result = await playerService.deletePlayer(id);
            ctx.send(result);
        } catch (err) {
            console.error('Error in deletePlayer controller:', err);
            ctx.badRequest(err.message);
        }
    },

    async getPlayers(ctx) {
        try {
            const result = await playerService.getPlayers();
            ctx.send({ result });
        } catch (err) {
            console.error('Error in getPlayers controller:', err);
            ctx.badRequest(err.message);
        }
    },
};
