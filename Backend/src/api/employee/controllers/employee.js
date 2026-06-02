'use strict';

const employeeService = require('../services/employee');

module.exports = {

	// ── Self-service ──────────────────────────────────────────────────────────

	// @ts-ignore
	async getMe(ctx) {
		try {
			const profile = await employeeService.getEmployeeProfile(ctx.state.user.id);
			ctx.send(profile);
		} catch (err) {
			console.error('Error in getMe (employee) controller:', err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	},

	// @ts-ignore
	async updateMe(ctx) {
		try {
			const { username, email, address, phone } = ctx.request.body;
			const profile = await employeeService.updateEmployeeProfile(ctx.state.user.id, { username, email, address, phone });
			ctx.send({ message: 'Profile updated successfully', profile });
		} catch (err) {
			console.error('Error in updateMe (employee) controller:', err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	},

	// ── Manager management ────────────────────────────────────────────────────

	// @ts-ignore
	async registerEmployee(ctx) {
		try {
			const { username, email, password, address, phone, terrainId } = ctx.request.body;
			const { user, employeeProfile } = await employeeService.registerEmployee({ username, email, password, address, phone, terrainId });

			ctx.send({
				message: `Employee ${user.username} registered successfully`,
				user
			});
		} catch (err) {
			console.error("Error in registerEmployee controller:", err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}

	},

	// @ts-ignore
	async updateEmployee(ctx) {
		try {
			const { id } = ctx.params;
			const { username, email, password, address, phone } = ctx.request.body;
			const user = await employeeService.updateEmployee(id, { username, email, password, address, phone });
			ctx.send({
				message: `Employee ${user.username} updated successfully`,
				user
			});
		} catch (err) {
			console.error("Error in updateEmployee controller:", err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	},

	// @ts-ignore
	async deleteEmployee(ctx) {
		try {
			const { id } = ctx.params;
			const result = await employeeService.deleteEmployee(id);
			ctx.send({
				message: `Employee ${id} deleted successfully`,
				result
			});
		} catch (err) {
			console.error("Error in deleteEmployee controller:", err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	},

	// @ts-ignore
	async getEmployees(ctx) {
		try {
			const result = await employeeService.getEmployees();
			ctx.send({result});
		} catch (err) {
			console.error("Error in getEmployees controller:", err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	},

	// @ts-ignore
	async assignTerrain(ctx) {
		try {
			const { employeeId, terrainId } = ctx.params;
			const result = await employeeService.assignTerrain(employeeId, terrainId);
			ctx.send({
				message: `Terrain ${terrainId} assigned to employee ${employeeId}`,
				result
			});
		} catch (err) {
			console.error("Error in assignTerrain controller:", err);
			// @ts-ignore
			ctx.badRequest(err.message);
		}
	}

};
