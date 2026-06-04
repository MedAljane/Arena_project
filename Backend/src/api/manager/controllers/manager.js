const adminService = require('../services/manager');

module.exports = {

    // ── Self-service ──────────────────────────────────────────────────────────

    
    async getMe(ctx) {
        try {
            const profile = await adminService.getManagerProfile(ctx.state.user.id);
            ctx.send(profile);
        } catch (err) {
            console.error('Error in getMe (manager) controller:', err);
            
            ctx.badRequest(err.message);
        }
    },

    
    async updateMe(ctx) {
        try {
            const { username, email, address, phone } = ctx.request.body;
            const profile = await adminService.updateManagerProfile(ctx.state.user.id, { username, email, address, phone });
            ctx.send({ message: 'Profile updated successfully', profile });
        } catch (err) {
            console.error('Error in updateMe (manager) controller:', err);
            
            ctx.badRequest(err.message);
        }
    },

    // ── Admin management ──────────────────────────────────────────────────────

    
    async registerManager(ctx) {
        try {

            const { username, email, password, address, phone } = ctx.request.body;
            const {user, managerProfile} = await adminService.registerManager({ username, email, password, address, phone });

            ctx.send({
                message: `Manager ${user.username} registered successfully`,
                user
            });
        } catch (err) {
            console.error("Error in registerManager controller:", err);
            
            ctx.badRequest(err.message);
        }

    },

    
    async updateManager(ctx) {
        try {
            const { id } = ctx.params;
            const { username, email, password, address, phone } = ctx.request.body;
            const user = await adminService.updateManager(id, { username, email, password, address, phone });
            ctx.send({
                message: `Manager ${user.username} updated successfully`,
                user
            });
        }catch (err) {
            console.error("Error in updateManager controller:", err);
            
            ctx.badRequest(err.message);
        }
    },

    
    async deleteManager(ctx) {
        try {
            const { id } = ctx.params;
            const result = await adminService.deleteManager(id);
            ctx.send({
                message: `Manager ${id} deleted successfully`,
                result
            });
        }catch (err) {
            console.error("Error in deleteManager controller:", err);
            
            ctx.badRequest(err.message);
        }
    },

    
    async getManagers(ctx) {
        try {
            const { id } = ctx.params;
            const result = await adminService.getManagers();
            ctx.send({result});
        }catch (err) {
            console.error("Error in getManagers controller:", err);
            
            ctx.badRequest(err.message);
        }
    },



};