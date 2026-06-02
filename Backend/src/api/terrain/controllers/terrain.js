'use strict';

const terrainService = require('../services/terrain');

module.exports = {

	// @ts-ignore
	async createTerrainController(ctx) {
		try {
			const { Type, campusId, employeeId } = ctx.request.body;
			const terrain = await terrainService.createTerrain({ Type, campusId, employeeId });
			ctx.send({ message: 'Terrain created successfully', terrain });
		} catch (err) {
			console.error('Error in createTerrainController:', err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	},

	// @ts-ignore
	async updateTerrainController(ctx) {
		try {
			const { id } = ctx.params;
			const { Type, campusId, employeeId } = ctx.request.body;
			const terrain = await terrainService.updateTerrain(id, { Type, campusId, employeeId });
			ctx.send({ message: 'Terrain updated successfully', terrain });
		} catch (err) {
			console.error('Error in updateTerrainController:', err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	},

	// @ts-ignore
	async deleteTerrainController(ctx) {
		try {
			const { id } = ctx.params;
			const result = await terrainService.deleteTerrain(id);
			ctx.send({ message: 'Terrain deleted successfully', result });
		} catch (err) {
			console.error('Error in deleteTerrainController:', err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	},

	// @ts-ignore
	async getTerrainByIdController(ctx) {
		try {
			const { id } = ctx.params;
			const terrain = await terrainService.getTerrainById(id);
			ctx.send({ terrain });
		} catch (err) {
			console.error('Error in getTerrainByIdController:', err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	},

	// @ts-ignore
	async getTerrainsController(ctx) {
		try {
			const { campusId } = ctx.query;
			const terrains = await terrainService.getTerrains(campusId);
			ctx.send({ terrains });
		} catch (err) {
			console.error('Error in getTerrainsController:', err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	}

};
