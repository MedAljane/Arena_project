const { routes } = require("../../auth/routes/auth");

module.exports = {
	routes: [
		// ── Self-service (employee acts on own profile) ───────────────────────
		{
			method: 'GET',
			path: '/employee/me',
			handler: 'employee.getMe',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isEmployee']
			},
		},
		{
			method: 'PUT',
			path: '/employee/me',
			handler: 'employee.updateMe',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isEmployee']
			},
		},

		// ── Manager management ────────────────────────────────────────────────
		{
			method: 'POST',
			path: '/manager/register-employee',
			handler: 'employee.registerEmployee',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isManager']
			},
		},

		{
			method: 'PUT',
			path: '/manager/update-employee/:id',
			handler: 'employee.updateEmployee',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isManager']
			},
		},

		{
			method: 'DELETE',
			path: '/manager/delete-employee/:id',
			handler: 'employee.deleteEmployee',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isManager']
			},
		},

		{
			method: 'GET',
			path: '/manager/employees',
			handler: 'employee.getEmployees',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isManager']
			},
		},

		// public listing for players
		{
			method: 'GET',
			path: '/player/employees',
			handler: 'employee.getEmployees',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isPlayer']
			},
		},

		// admin read-only
		{
			method: 'GET',
			path: '/admin/employees',
			handler: 'employee.getEmployees',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isAdmin']
			},
		},

		// assign terrain to employee
		{
			method: 'POST',
			path: '/manager/assign-employee/:employeeId/terrain/:terrainId',
			handler: 'employee.assignTerrain',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isManager']
			},
		}

	]
};
