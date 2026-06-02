const { sendEmail } = require("../../../utils/email");

module.exports = {

    // ── Self-service helpers ──────────────────────────────────────────────────

    // @ts-ignore
    async getManagerProfile(userId) {
        const profile = await strapi.db.query('api::manager.manager').findOne({
            where: { user: userId },
            populate: ['user'],
        });
        if (!profile) throw new Error('Manager profile not found');
        return {
            id: profile.id,
            nom: profile.nom,
            address: profile.address,
            phone: profile.phone,
            firebaseUid: profile.firebaseUid,
            fcmToken: profile.fcmToken,
            user: profile.user ? {
                id: profile.user.id,
                username: profile.user.username,
                email: profile.user.email,
                user_role: 'manager',
            } : null,
        };
    },

    // @ts-ignore
    async updateManagerProfile(userId, { username, email, address, phone }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        if (email && email !== user.email) {
            const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
            if (existing) throw new Error('Email already in use');
        }

        await strapi.entityService.update('plugin::users-permissions.user', userId, {
            data: { username: username || user.username, email: email || user.email },
        });

        const managerProfile = await strapi.db.query('api::manager.manager').findOne({ where: { user: userId } });
        if (managerProfile) {
            await strapi.entityService.update('api::manager.manager', managerProfile.id, {
                data: { address: address || null, phone: phone || null },
            });
        }

        return this.getManagerProfile(userId);
    },

    // ── Admin management ──────────────────────────────────────────────────────

    // @ts-ignore
    async registerManager({ username, email, password, address, phone }) {

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
            user_role: 'manager'
        });

        console.log('User registered:', user.username, user.id);

        // Create manager profile linked to the user
        let manager;
        try {
            manager = await strapi.entityService.create('api::manager.manager', {
                data: {
                    user: user.id,
                    address: address || null,
                    phone: phone || null,
                    publishedAt: new Date(),
                    fcmToken: `manager-${user.id}`,
                    firebaseUid: `manager-${user.id}`,
                    nom: username
                },
                populate: '*'
            });
            console.log(manager);
            console.log('Manager profile created for:', user.username, 'Profile ID:', manager.id);
        } catch (err) {
            console.error('Error creating manager profile:', err);
            throw new Error('Failed to create manager profile');
        }

        try {
            await sendEmail(
                email,
                'Welcome to the Arena Managers System',
                `Hello ${username},\n\nYour manager account has been successfully created. \n\nPlease use these credentials to login, and remember to change you password.\n\n\tEmail: ${email}\n\tPassword: ${password}\n\n\nBest regards,\nArena Team`
            );
            console.log('Welcome email sent to:', email);
        } catch (err) {
            console.error('Error sending welcome email:', err);
        }
        const managerProfile = await strapi.db.query('api::manager.manager').findOne({ where: { user: { id: user.id } }, populate: ['manager'] });

        return { user, managerProfile };
    },

    // @ts-ignore
    async updateManager(id, { username, email, password, address, phone }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id } });

        if (!user) {
            throw new Error('User not found');
        }
        if (user.user_role !== 'manager') {
            throw new Error('User is not a manager');
        }

        if (email && email !== user.email) {
            const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
            if (existing) {
                throw new Error('Email already exists');
            }

            const updatedUser = await strapi.entityService.update('plugin::users-permissions.user', id, {
                data: { username, email }
            });

            const managerProfile = await strapi.db.query('api::manager.manager').findOne({ where: { user: id } });

            if (!managerProfile) {
                throw new Error('Manager profile not found');
            }

            try {
                await strapi.entityService.update('api::manager.manager', managerProfile.id, {
                    data: { address, phone }
                });
            } catch (err) {
                console.error('Error updating manager profile:', err);
                throw new Error('Failed to update manager profile');
            }

            return updatedUser;

        }

    },

    // @ts-ignore
    async deleteManager(id) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id } });

        if (!user) {
            throw new Error('User not found');
        }
        if (user.user_role !== 'manager') {
            throw new Error('User is not a manager');
        }

        const managerProfile = await strapi.db.query('api::manager.manager').findOne({ where: { user: id } });

        if (!managerProfile) {
            throw new Error('Manager profile not found');
        }

        try {
            await strapi.entityService.delete('api::manager.manager', managerProfile.id);
        } catch (err) {
            console.error('Error deleting manager profile:', err);
            throw new Error('Failed to delete manager profile');
        }

        try {
            await strapi.entityService.delete('plugin::users-permissions.user', id);
        } catch (err) {
            console.error('Error deleting user:', err);
            throw new Error('Failed to delete user');
        }

        return {message: `Manager with ID ${id} deleted successfully`};
    },

    // @ts-ignore
    async getManagers() {
        const users = await strapi.db.query('plugin::users-permissions.user').findMany({
            where: { user_role: 'manager' },
        });

        // @ts-ignore
        const result = await Promise.all(users.map(async (user) => {
            const profile = await strapi.db.query('api::manager.manager').findOne({ where: { user: user.id } });
            return {
                id: user.id,
                username: user.username,
                email: user.email,
                address: profile?.address || null,
                phone: profile?.phone || null,
                fcmToken: profile?.fcmToken || `manager-${user.id}`,
                firebaseUid: profile?.firebaseUid || `manager-${user.id}`,
                nom: user.username,
            };
        }));

        return result;
    }



}