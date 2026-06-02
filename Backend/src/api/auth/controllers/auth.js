const authService = require('../services/auth');

module.exports = {

    // @ts-ignore
    async register(ctx) {
        try {
            const user = await authService.registerUser(ctx.request.body);
            ctx.send(user);
        } catch (err) {
            // @ts-ignore

            ctx.badRequest(err.message);

        }

    },

    // @ts-ignore
    async login(ctx) {
        try {
            const data = await authService.loginUser(ctx.request.body);
            ctx.send(data);
        } catch (err) {
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    },

    // @ts-ignore
    async resetPassword(ctx) {
        const { token, password } = ctx.request.body;
        try {
            await authService.resetPassword(token, password);
            ctx.send({ message: 'Password reset successful' });
        } catch (err) {
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    },

    // @ts-ignore
    async changePassword(ctx) {

        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('User not authenticated');
            const { currentPassword, newPassword } = ctx.request.body;
            if (!currentPassword || !newPassword) {
                return ctx.badRequest('Current and new passwords are required');
            }

            try {
                await authService.changePassword(user.id, currentPassword, newPassword);
                ctx.send({ message: 'Password changed successfully' });
            } catch (err) {
                // @ts-ignore
                ctx.badRequest(err.message);
            }
        } catch (err) {
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    },

    // @ts-ignore
    async forgotPassword(ctx) {
        try {
            await authService.forgotPassword(ctx.request.body.email);
            ctx.send({ message: 'Password reset email sent' });
        } catch (err) {
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    },

    // @ts-ignore
    async getMe(ctx) {
        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('User not authenticated');
            const data = await authService.getMe(user.id);
            ctx.send(data);
        } catch (err) {
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    },

    // @ts-ignore
    async logoutController(ctx) {
        try {
            const authHeader = ctx.request.headers.authorization;
            if (!authHeader) return ctx.badRequest('No token provided');
            const token = authHeader.split(' ')[1];
            await authService.logout(token);
            ctx.send({ message: 'Logged out' });
        } catch (err) {
            // @ts-ignore
            ctx.badRequest(err.message);
        }
    }

}