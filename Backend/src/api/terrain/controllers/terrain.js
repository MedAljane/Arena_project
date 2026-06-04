'use strict';

const terrainService = require('../services/terrain');

module.exports = {

	
	async createTerrainController(ctx) {
		try {
			const { Type, campusId, employeeId } = ctx.request.body;
			const terrain = await terrainService.createTerrain({ Type, campusId, employeeId });
			ctx.send({ message: 'Terrain created successfully', terrain });
		} catch (err) {
			console.error('Error in createTerrainController:', err);
			
			ctx.badRequest(err.message);
		}
	},

	
	async updateTerrainController(ctx) {
		try {
			const { id } = ctx.params;
			const { Type, campusId, employeeId } = ctx.request.body;
			const terrain = await terrainService.updateTerrain(id, { Type, campusId, employeeId });
			ctx.send({ message: 'Terrain updated successfully', terrain });
		} catch (err) {
			console.error('Error in updateTerrainController:', err);
			
			ctx.badRequest(err.message);
		}
	},

	
	async deleteTerrainController(ctx) {
		try {
			const { id } = ctx.params;
			const result = await terrainService.deleteTerrain(id);
			ctx.send({ message: 'Terrain deleted successfully', result });
		} catch (err) {
			console.error('Error in deleteTerrainController:', err);
			
			ctx.badRequest(err.message);
		}
	},

	
	async getTerrainByIdController(ctx) {
		try {
			const { id } = ctx.params;
			const terrain = await terrainService.getTerrainById(id);
			ctx.send({ terrain });
		} catch (err) {
			console.error('Error in getTerrainByIdController:', err);
			
			ctx.badRequest(err.message);
		}
	},

	
	async getTerrainsController(ctx) {
		try {
			const { campusId } = ctx.query;
			const terrains = await terrainService.getTerrains(campusId);
			ctx.send({ terrains });
		} catch (err) {
			console.error('Error in getTerrainsController:', err);
			
			ctx.badRequest(err.message);
		}
	}

};
