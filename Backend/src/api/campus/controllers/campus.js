const campusService = require('../services/campus');

module.exports = {
    
    
    async createCampusController(ctx){
        const userId = ctx.state.user.id;
        const { name, description, address, phone, nbTerrains, mainImage, galleryImages } = ctx.request.body;

        try {
            const managerProfile = await strapi.db.query('api::manager.manager').findOne({ where: { user: userId } });
            if (!managerProfile) {
                return ctx.badRequest('Manager profile not found for this user');
            }
            const managerId = managerProfile.id;
            const campus = await campusService.createCampus(name, description, address, phone, nbTerrains, mainImage, galleryImages, managerId);
            ctx.send({
                message: `Campus ${campus.Name} created successfully`,
                campus
            });
        } catch (err) {
            console.error("Error in createCampusController:", err);
            
            ctx.badRequest(err.message);
        }
    },
    
    async updateCampusController(ctx){
        const { id } = ctx.params;
        const data = ctx.request.body;

        try {
            const campus = await campusService.updateCampus(id, data);
            ctx.send({
                message: `Campus ${campus.Name} updated successfully`,
                campus
            });
        } catch (err) {
            console.error("Error in updateCampusController:", err);
            
            ctx.badRequest(err.message);
        }
    },

    
    async deleteCampusController(ctx){
        const { id } = ctx.params;

        try {
            const result = await campusService.deleteCampus(id);
            ctx.send({
                message: `Campus with ID ${id} deleted successfully`,
                result
            });
        } catch (err) {
            console.error("Error in deleteCampusController:", err);
            
            ctx.badRequest(err.message);
        }
    },

    
    async getCampusesController(ctx){
        try {
            const campuses = await campusService.getCampuses();
            ctx.send(campuses);
        } catch (err) {
            console.error("Error in getCampusesController:", err);
            
            ctx.badRequest(err.message);
        }
    },

    
    async getCampusByManagerController(ctx){
        const managerId = ctx.state.user.id;

        try {
            const campus = await campusService.getCampusByManager(managerId);
            if (!campus) {
                ctx.notFound('No campus found for this manager');
                return;
            }
            ctx.send(campus);
        } catch (err) {
            console.error("Error in getCampusByManagerController:", err);
            
            ctx.badRequest(err.message);
        }
    },

    
    async getCampusByIdController(ctx){
        const { id } = ctx.params;

        try {
            const campus = await campusService.getCampusById(id);
            if (!campus) {
                ctx.notFound('Campus not found');
                return;
            }
            ctx.send(campus);
        } catch (err) {
            console.error("Error in getCampusByIdController:", err);
            
            ctx.badRequest(err.message);
        }
    },

}