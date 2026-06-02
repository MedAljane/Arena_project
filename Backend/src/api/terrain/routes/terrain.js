module.exports = {
	routes: [
		{
			method: 'POST',
			path: '/manager/create-terrain',
			handler: 'terrain.createTerrainController',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isManager']
			}
		},

		{
			method: 'PUT',
			path: '/manager/update-terrain/:id',
			handler: 'terrain.updateTerrainController',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isManager']
			}
		},

		{
			method: 'DELETE',
			path: '/manager/delete-terrain/:id',
			handler: 'terrain.deleteTerrainController',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isManager']
			}
		},

		{
			method: 'GET',
			path: '/manager/get-terrain/:id',
			handler: 'terrain.getTerrainByIdController',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isManager']
			}
		},

		{
			method: 'GET',
			path: '/manager/get-terrains',
			handler: 'terrain.getTerrainsController',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isManager']
			}
		},

		// Admin read-only
		{
			method: 'GET',
			path: '/admin/terrains',
			handler: 'terrain.getTerrainsController',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isAdmin']
			}
		},

		// Player routes
		{
			method: 'GET',
			path: '/player/get-terrains',
			handler: 'terrain.getTerrainsController',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isPlayer']
			}
		},

		{
			method: 'GET',
			path: '/player/get-terrain/:id',
			handler: 'terrain.getTerrainByIdController',
			config: {
				auth: false,
				policies: ['global::authMiddleware', 'global::isPlayer']
			}
		}
	]
};
