const adminService = require('../services/admin');

module.exports = {

    
    async registerAdmin(ctx) {
        try {

            const { username, email, password } = ctx.request.body;
            const { user } = await adminService.registerAdmin({ username, email, password });

            ctx.send({
                message: `Admin ${user.username} registered successfully`,
                user
            });
        } catch (err) {
            console.error("Error in registerAdmin controller:", err);
            
            ctx.badRequest(err.message);
        }

    },

    
    async updateAdmin(ctx) {
        try {
            const { id } = ctx.params;
            const { username, email } = ctx.request.body;
            const user = await adminService.updateAdmin(id, { username, email });
            ctx.send({
                message: `Admin ${user.username} updated successfully`,
                user
            });
        }catch (err) {
            console.error("Error in updateAdmin controller:", err);
            
            ctx.badRequest(err.message);
        }
    },

    
    async deleteAdmin(ctx) {
        try {
            const { id } = ctx.params;
            const result = await adminService.deleteAdmin(id);
            ctx.send({
                message: `Admin ${id} deleted successfully`,
                result
            });
        }catch (err) {
            console.error("Error in deleteAdmin controller:", err);
            
            ctx.badRequest(err.message);
        }
    },

    
    async getAdmins(ctx) {
        try {
            const { id } = ctx.params;
            const result = await adminService.getAdmins();
            ctx.send({result});
        }catch (err) {
            console.error("Error in getAdmins controller:", err);
            
            ctx.badRequest(err.message);
        }
    },



};