const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'secret';
const crypto = require('crypto');
const { pop } = require('../../../../config/middlewares');
const { revoke } = require('../../../utils/tokenBlacklist');

module.exports = {
    // @ts-ignore
    async registerUser({ username, email, password, address, phone }) {

        // create user in global user table
        const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });

        if (existing) {
            throw new Error('Email already exists');
        }

        const role = await strapi.db.query('plugin::users-permissions.role').findOne({ where: { type: 'authenticated' } });

        const user = await strapi.plugins['users-permissions'].services.user.add({
            username,
            email,
            password,
            role: role.id,
            user_role: 'player'
        });

        console.log('User registered:', user.username, user.id);

        // Create player profile linked to the user
        try {
            const player = await strapi.entityService.create('api::player.player', {
                data: {
                    user: user.id,
                    address: address || null,
                    phone: phone || null,
                    publishedAt: new Date()
                },
                populate: '*'
            });
            console.log(player);
            console.log('User profile created for:', user.username, 'Profile ID:', player.id);
            return { user, profile: player };
        } catch (err) {
            console.error('Error creating user profile:', err);
            throw new Error('Failed to create user profile');
        }
    },

    // @ts-ignore
    async loginUser({ email, password }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });

        if (!user) {
            throw new Error('Invalid email or password');
        }

        const valid = await strapi.plugins['users-permissions'].services.user.validatePassword(password, user.password);

        if (!valid) {
            throw new Error('Invalid email or password');
        }

        const token = jwt.sign({ id: user.id, user_role: user.user_role }, JWT_SECRET, { expiresIn: '7d' });
        return { user, token };
    },

    // @ts-ignore
    async resetPassword(token, password) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { resetPasswordToken: token } });

        if (!user) {
            throw new Error('Invalid token');
        }

        await strapi.plugins['users-permissions'].services.user.edit(user.id, { password });
        await strapi.db.query('plugin::users-permissions.user').update({ where: { id: user.id }, data: { resetPasswordToken: null } });
    },

    // @ts-ignore
    async changePassword(userId, currentPassword, newPassword) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) {
            throw new Error('User not found');
        }
        const valid = await strapi.plugins['users-permissions'].services.user.validatePassword(currentPassword, user.password);
        if (!valid) {
            throw new Error('Current password is incorrect');
        }

        await strapi.plugins['users-permissions'].services.user.edit(user.id, { password: newPassword });
    },

    // @ts-ignore,
    async forgotPassword(email) {
        const { sendEmail } = require('../../../utils/email');
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });

        if (!user) {
            throw new Error('User not found');
        }

        const token = crypto.randomBytes(32).toString('hex');

        await strapi.db.query('plugin::users-permissions.user').update({ where: { id: user.id }, data: { resetPasswordToken: token } });

        // const resetLink = `${process.env.FRONTEND_URL}/reset-password?token=${token}`;
        // await sendEmail(email, 'Password Reset', `Click the link to reset your password: ${resetLink}`);
        try {
            await sendEmail(email, 'Password Reset', `use this token to reset your password: ${token}`);
        } catch (err) {
            console.error('Error sending password reset email:', err);
            throw new Error('Failed to send password reset email');
        }

        return { message: 'Password reset email sent' };
    },

    // @ts-ignore
    async getMe(userId) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId }, populate: ['role'] });

        if (!user) throw new Error('User not found');

        console.log('Fetching profile for user:', user.username, 'ID:', user.id);
        const playerProfile = await strapi.db.query('api::player.player').findOne({ where: { user: { id: userId } }, populate: ['player'] });
        if (!playerProfile) {
            console.warn('No player profile found for user:', user.username);
            return { user, profile: null };
        }
        return { user, profile: playerProfile };
    },

    // @ts-ignore
    async logout(token) {
        if (!token) throw new Error('No token');

        try {
            const decoded = jwt.verify(token, JWT_SECRET);
            let ttlMs = 0;
            if (decoded && typeof decoded === 'object' && 'exp' in decoded) {
                const exp = Number(decoded.exp);
                ttlMs = exp > 0 ? exp * 1000 - Date.now() : 0;
            }
            revoke(token, ttlMs > 0 ? ttlMs : 0);
        } catch (err) {
            // token invalid/expired — still revoke to force rejection if somehow accepted elsewhere
            revoke(token);
        }
    }
}