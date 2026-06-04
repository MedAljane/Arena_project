const errors = require('@strapi/utils');


module.exports = async (ctx) => {
    const user = ctx.state.user;

    if (!user || user.user_role !== 'admin') {
        const msg = 'You must be an admin to access this resource';
        console.log(" Policy: Access denied - not an admin");
        
        ctx.status = 403;
        ctx.body = {
            data: null,
            errors: {
                status: 403,
                name: 'ForbiddenError',
                message: msg,
                details:{}
            }
        };
        return false;
    }


    console.log(`Policy: Access granted (Admin)- ${user.username} is doing something...`);
    return true;


}