'use strict';

const { sendEmail } = require("../../../utils/email");

module.exports = {

	// ── Self-service helpers ──────────────────────────────────────────────────

	// @ts-ignore
	async getEmployeeProfile(userId) {
		const profile = await strapi.db.query('api::employee.employee').findOne({
			where: { User: userId },
			populate: ['User', 'terrain'],
		});
		if (!profile) throw new Error('Employee profile not found');
		return {
			id: profile.id,
			nom: profile.nom,
			address: profile.address,
			phone: profile.phone,
			firebaseUid: profile.firebaseUid,
			fcmToken: profile.fcmToken,
			terrain: profile.terrain || null,
			user: profile.User ? {
				id: profile.User.id,
				username: profile.User.username,
				email: profile.User.email,
				user_role: 'employee',
			} : null,
		};
	},

	// @ts-ignore
	async updateEmployeeProfile(userId, { username, email, address, phone }) {
		const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
		if (!user) throw new Error('User not found');

		if (email && email !== user.email) {
			const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
			if (existing) throw new Error('Email already in use');
		}

		await strapi.entityService.update('plugin::users-permissions.user', userId, {
			data: { username: username || user.username, email: email || user.email },
		});

		const employeeProfile = await strapi.db.query('api::employee.employee').findOne({ where: { User: userId } });
		if (employeeProfile) {
			await strapi.entityService.update('api::employee.employee', employeeProfile.id, {
				data: { address: address || null, phone: phone || null },
			});
		}

		return this.getEmployeeProfile(userId);
	},

	// ── Manager management ────────────────────────────────────────────────────

	// @ts-ignore
	async registerEmployee({ username, email, password, address, phone, terrainId }) {

		const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
		if (existing) throw new Error('Email already exists');

		const role = await strapi.db.query('plugin::users-permissions.role').findOne({ where: { type: 'authenticated' } });

		const user = await strapi.plugins['users-permissions'].services.user.add({
			username,
			email,
			password,
			role: role.id,
			user_role: 'employee'
		});

		const employee = await strapi.entityService.create('api::employee.employee', {
			data: {
				User: user.id,
				address: address || null,
				phone: phone || null,
				publishedAt: new Date(),
				fcmToken: `employee-${user.id}`,
				firebaseUid: `employee-${user.id}`,
				nom: username
			},
			populate: '*'
		});

		// FIX: keep both sides of the relation in sync
		if (terrainId) {
			await strapi.entityService.update('api::terrain.terrain', terrainId, {
				data: { employee: employee.id }
			});
			// was missing: employee must also know its terrain
			await strapi.entityService.update('api::employee.employee', employee.id, {
				data: { terrain: terrainId }
			});
		}

		try {
			await sendEmail(
				email,
				'Welcome to the Arena Employees System',
				`Hello ${username},\n\nYour employee account has been created.\n\nEmail: ${email}\nPassword: ${password}\n\nBest regards,\nArena Team`
			);
		} catch (err) {
			console.error('Error sending welcome email:', err);
		}

		const employeeProfile = await strapi.db.query('api::employee.employee').findOne({ where: { User: { id: user.id } }, populate: ['User'] });
		return { user, employeeProfile };
	},

	// @ts-ignore
	async updateEmployee(id, { username, email, address, phone }) {
		const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id } });
		if (!user) throw new Error('User not found');
		if (user.user_role !== 'employee') throw new Error('User is not an employee');

		// FIX: validate email uniqueness before writing, but don't gate everything on it
		if (email && email !== user.email) {
			const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
			if (existing) throw new Error('Email already in use');
		}

		// FIX: always update — not only when email changes
		const updatedUser = await strapi.entityService.update('plugin::users-permissions.user', id, {
			data: { username, email }
		});

		const employeeProfile = await strapi.db.query('api::employee.employee').findOne({ where: { User: id } });
		if (!employeeProfile) throw new Error('Employee profile not found');

		await strapi.entityService.update('api::employee.employee', employeeProfile.id, {
			data: { address: address || null, phone: phone || null }
		});

		return updatedUser;
	},

	// @ts-ignore
	async deleteEmployee(id) {
		const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id } });
		if (!user) throw new Error('User not found');
		if (user.user_role !== 'employee') throw new Error('User is not an employee');

		const employeeProfile = await strapi.db.query('api::employee.employee').findOne({ where: { User: id } });
		if (!employeeProfile) throw new Error('Employee profile not found');

		await strapi.entityService.delete('api::employee.employee', employeeProfile.id);
		await strapi.entityService.delete('plugin::users-permissions.user', id);

		return { message: `Employee with ID ${id} deleted successfully` };
	},

	// @ts-ignore
	async getEmployees() {
		const users = await strapi.db.query('plugin::users-permissions.user').findMany({
			where: { user_role: 'employee' },
		});

		// @ts-ignore
		const result = await Promise.all(users.map(async (user) => {
			const profile = await strapi.db.query('api::employee.employee').findOne({ where: { User: user.id }, populate: ['terrain'] });
			return {
				id: user.id,
				username: user.username,
				email: user.email,
				address: profile?.address || null,
				phone: profile?.phone || null,
				terrain: profile?.terrain || null,
				fcmToken: profile?.fcmToken || `employee-${user.id}`,
				firebaseUid: profile?.firebaseUid || `employee-${user.id}`,
				nom: user.username,
			};
		}));

		return result;
	},

	// @ts-ignore
	async assignTerrain(employeeId, terrainId) {
		const employeeProfile = await strapi.db.query('api::employee.employee').findOne({ where: { User: employeeId }, populate: ['terrain'] });
		if (!employeeProfile) throw new Error('Employee profile not found');

		await strapi.entityService.update('api::employee.employee', employeeProfile.id, {
			data: { terrain: terrainId }
		});

		await strapi.entityService.update('api::terrain.terrain', terrainId, {
			data: { employee: employeeProfile.id }
		});

		return { employeeProfileId: employeeProfile.id, terrainId };
	}

};
