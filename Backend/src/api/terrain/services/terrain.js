'use strict';

module.exports = {
	// @ts-ignore
	async createTerrain({ Type, campusId, employeeId }) {
		if (!Type) throw new Error('Type is required');

		const campusExists = await strapi.db.query('api::campus.campus').findOne({ where: { id: campusId } });
		if (!campusExists) throw new Error('Campus not found');

		// Resolve user ID → employee profile ID before the first write
		let profileId;
		if (employeeId) {
			const profile = await strapi.db.query('api::employee.employee').findOne({ where: { User: employeeId } });
			if (!profile) throw new Error('Employee profile not found for the provided user ID');
			profileId = profile.id;
		}

		const terrain = await strapi.entityService.create('api::terrain.terrain', {
			data: {
				Type,
				campus: campusId || null,
				employee: profileId || null,
				publishedAt: new Date()
			},
			populate: ['employee', 'week_agenda', 'campus']
		});

		// FIX: keep employee's terrain in sync
		if (profileId) {
			await strapi.entityService.update('api::employee.employee', profileId, {
				data: { terrain: terrain.id }
			});
		}

		return terrain;
	},

	// @ts-ignore
	async updateTerrain(id, { Type, campusId, employeeId }) {
		const existing = await strapi.db.query('api::terrain.terrain').findOne({
			where: { id },
			populate: ['employee']
		});
		if (!existing) throw new Error('Terrain not found');

		// FIX: resolve user ID → profile ID BEFORE building the update payload
		// (old code wrote the raw user ID in the first update, then corrected it in a second)
		let profileId;
		if (employeeId !== undefined) {
			const profile = await strapi.db.query('api::employee.employee').findOne({ where: { User: employeeId } });
			if (!profile) throw new Error('Employee profile not found for the provided user ID');
			profileId = profile.id;
		}

		const data = {};
		if (Type !== undefined) data.Type = Type;
		if (campusId !== undefined) data.campus = campusId;
		if (profileId !== undefined) data.employee = profileId;

		// FIX: single write with correct data; return its result (not a stale pre-correction result)
		const updated = await strapi.entityService.update('api::terrain.terrain', id, {
			data,
			populate: ['employee', 'week_agenda', 'campus']
		});

		// FIX: update employee terrain and clear the previous employee's if it changed
		if (profileId !== undefined) {
			await strapi.entityService.update('api::employee.employee', profileId, {
				data: { terrain: id }
			});

			const prevProfileId = existing.employee?.id;
			if (prevProfileId && prevProfileId !== profileId) {
				await strapi.entityService.update('api::employee.employee', prevProfileId, {
					data: { terrain: null }
				});
			}
		}

		return updated;
	},

	// @ts-ignore
	async deleteTerrain(id) {
		const existing = await strapi.db.query('api::terrain.terrain').findOne({ where: { id }, populate: ['employee'] });
		if (!existing) throw new Error('Terrain not found');

		// Clear the assigned employee's terrain before deletion
		if (existing.employee?.id) {
			await strapi.entityService.update('api::employee.employee', existing.employee.id, {
				data: { terrain: null }
			});
		}

		await strapi.entityService.delete('api::terrain.terrain', id);
		return { message: `Terrain ${id} deleted` };
	},

	// @ts-ignore
	async getTerrainById(id) {
		const terrain = await strapi.db.query('api::terrain.terrain').findOne({ where: { id }, populate: ['employee', 'week_agenda', 'campus'] });
		if (!terrain) throw new Error('Terrain not found');
		return terrain;
	},

	// @ts-ignore
	async getTerrains(campusId) {
		const where = {};
		if (campusId) where.campus = campusId;
		return await strapi.db.query('api::terrain.terrain').findMany({ where, populate: ['employee', 'week_agenda', 'campus'] });
	}
};
