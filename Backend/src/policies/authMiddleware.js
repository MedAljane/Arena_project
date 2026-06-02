const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'secret';
const { isRevoked } = require('../utils/tokenBlacklist');

// @ts-ignore
module.exports = async (ctx) => {
    const authHeader = ctx.request.headers.authorization;

    if (!authHeader) {
        console.log(" Midlleware: No token provided");
        ctx.status = 401;
        ctx.body = { error: 'No token provided' };
        return;
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
        console.log(" Midlleware: token not properly formatted");
        ctx.status = 401;
        ctx.body = { error: 'Invalid token' };
        return;
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        
        if (isRevoked(token)) {
            ctx.status = 401;
            ctx.body = { error: 'Token revoked' };
            return;
        }

        ctx.state.user = decoded;
        const userId = typeof decoded === 'object' && decoded !== null ? decoded.id : null;

        if (!userId) {
            console.log(" Midlleware: Invalid user ID");
            ctx.status = 401;
            ctx.body = { error: 'Invalid user ID' };
            return;
        }

        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });

        if (!user) {
            console.log(" Midlleware: User not found");
            ctx.status = 401;
            ctx.body = { error: 'User not found' };
            return;
        }

        console.log(" Midlleware: User authenticated", user.username);

        ctx.state.user = user;

        return true;

    } catch (err) {
        // @ts-ignore
        console.log(" Midlleware: Invalid token", err.message);
        ctx.status = 401;
        ctx.body = { error: 'Invalid token' };
    }
};