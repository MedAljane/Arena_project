const auth = require("../services/auth");

module.exports = {

    routes: [
        {
            method: 'POST',
            path: '/auth/register',
            handler: 'auth.register',
            config: {
                auth: false
            }
        },
        {
            method: 'POST',
            path: '/auth/login',
            handler: 'auth.login',
            config: {
                auth: false
            }
        },
        {
            method: 'POST',
            path: '/auth/reset-password',
            handler: 'auth.resetPassword',
            config: {
                auth: false
            }
        },
        {
            method: 'POST',
            path: '/auth/change-password',
            handler: 'auth.changePassword',
            config: {
                auth: false,
                policies: ['global::authMiddleware']
            },
        },
        {
            method: 'POST',
            path: '/auth/forgot-password',
            handler: 'auth.forgotPassword',
            config: {
                auth: false
            }
        },
        {
            method: 'GET',
            path: '/auth/me',
            handler: 'auth.getMe',
            config: {
                auth: false,
                policies: ['global::authMiddleware']
            },
        },
        {
            method: 'POST',
            path: '/auth/logout',
            handler: 'auth.logoutController',
            config: { auth: false, policies: ['global::authMiddleware'] }
        }
    ]
}