'use strict';

module.exports = {

    // ── Self-service helpers ──────────────────────────────────────────────────

    // @ts-ignore
    async getPlayerProfile(userId) {
        const profile = await strapi.db.query('api::player.player').findOne({
            where: { user: userId },
            populate: ['user'],
        });
        if (!profile) throw new Error('Player profile not found');
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
                user_role: 'player',
            } : null,
        };
    },

    // @ts-ignore
    async updatePlayerProfile(userId, { username, email, address, phone }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        if (email && email !== user.email) {
            const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
            if (existing) throw new Error('Email already in use');
        }

        await strapi.entityService.update('plugin::users-permissions.user', userId, {
            data: { username: username || user.username, email: email || user.email },
        });

        const playerProfile = await strapi.db.query('api::player.player').findOne({ where: { user: userId } });
        if (playerProfile) {
            await strapi.entityService.update('api::player.player', playerProfile.id, {
                data: { address: address || null, phone: phone || null },
            });
        }

        return this.getPlayerProfile(userId);
    },

    // ── Admin management ──────────────────────────────────────────────────────

    async registerPlayer({ username, email, password, address, phone }) {
        const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
        if (existing) throw new Error('Email already exists');

        const role = await strapi.db.query('plugin::users-permissions.role').findOne({ where: { type: 'authenticated' } });

        const user = await strapi.plugins['users-permissions'].services.user.add({
            username,
            email,
            password,
            role: role.id,
            user_role: 'player',
        });

        const profile = await strapi.entityService.create('api::player.player', {
            data: {
                user: user.id,
                address: address || null,
                phone: phone || null,
                publishedAt: new Date(),
                fcmToken: `player-${user.id}`,
                firebaseUid: `player-${user.id}`,
                nom: username
            },
            populate: '*',
        });

        return { user, profile };
    },

    async updatePlayer(id, { username, email, address, phone }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id } });
        if (!user) throw new Error('User not found');
        if (user.user_role !== 'player') throw new Error('User is not a player');

        if (email && email !== user.email) {
            const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
            if (existing) throw new Error('Email already in use');
        }

        const updatedUser = await strapi.entityService.update('plugin::users-permissions.user', id, {
            data: { username, email },
        });

        const playerProfile = await strapi.db.query('api::player.player').findOne({ where: { user: id } });
        if (playerProfile) {
            await strapi.entityService.update('api::player.player', playerProfile.id, {
                data: { address: address || null, phone: phone || null },
            });
        }

        return updatedUser;
    },

    async deletePlayer(id) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id } });
        if (!user) throw new Error('User not found');
        if (user.user_role !== 'player') throw new Error('User is not a player');

        const playerProfile = await strapi.db.query('api::player.player').findOne({ where: { user: id } });
        if (playerProfile) {
            await strapi.entityService.delete('api::player.player', playerProfile.id);
        }

        await strapi.entityService.delete('plugin::users-permissions.user', id);
        return { message: `Player with ID ${id} deleted successfully` };
    },

    async getPlayers() {
        const users = await strapi.db.query('plugin::users-permissions.user').findMany({
            where: { user_role: 'player' },
        });

        const result = await Promise.all(users.map(async (user) => {
            const profile = await strapi.db.query('api::player.player').findOne({ where: { user: user.id } });
            return {
                id: user.id,
                username: user.username,
                email: user.email,
                address: profile?.address || null,
                phone: profile?.phone || null,
                fcmToken: profile?.fcmToken || `player-${user.id}`,
                firebaseUid: profile?.firebaseUid || `player-${user.id}`,
                nom: user.username,
            };
        }));

        return result;
    },
};
