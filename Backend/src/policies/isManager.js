const errors = require('@strapi/utils');

// @ts-ignore
module.exports = async (ctx) => {
    const user = ctx.state.user;

    if (!user || user.user_role !== 'manager') {
        const msg = 'You must be a manager to access this resource';
        console.log(" Policy: Access denied - not a manager");
        
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


    console.log(`Policy: Access granted (Manager)- ${user.username} is doing something...`);
    return true;


}