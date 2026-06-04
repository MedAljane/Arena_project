const { sendEmail } = require("../../../utils/email");

module.exports = {
    
    async registerAdmin({ username, email, password }) {

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
            user_role: 'admin'
        });

        console.log('User registered:', user.username, user.id);

        try {
            await sendEmail(
                email,
                'Welcome to the Arena Admins System',
                `Hello ${username},\n\nYour admin account has been successfully created. \n\nPlease use these credentials to login, and remember to change you password.\n\n\tEmail: ${email}\n\tPassword: ${password}\n\n\nBest regards,\nArena Team`
            );
            console.log('Welcome email sent to:', email);
        } catch (err) {
            console.error('Error sending welcome email:', err);
        }
        const managerProfile = await strapi.db.query('api::users-permissions.user').findOne({ where: { user: { id: user.id } }, populate: ['admin'] });

        return { user, managerProfile };
    },

    
    async updateAdmin(id, { username, email }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id } });

        if (!user) {
            throw new Error('User not found');
        }
        if (user.user_role !== 'admin') {
            throw new Error('User is not an admin');
        }

        if (email && email !== user.email) {
            const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
            if (existing) {
                throw new Error('Email already exists');
            }

            const updatedUser = await strapi.entityService.update('plugin::users-permissions.user', id, {
                data: { username, email }
            });

            return updatedUser;

        }

    },

    
    async deleteAdmin(id) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id } });

        if (!user) {
            throw new Error('User not found');
        }
        if (user.user_role !== 'admin') {
            throw new Error('User is not an admin');
        }

        try {
            await strapi.entityService.delete('plugin::users-permissions.user', id);
        } catch (err) {
            console.error('Error deleting user:', err);
            throw new Error('Failed to delete user');
        }

        return {message: `Admin with ID ${id} deleted successfully`};
    },

    
    async getAdmins() {
        const users = await strapi.db.query('plugin::users-permissions.user').findMany({
            where: { user_role: 'admin' },
        });

        
        const result = await Promise.all(users.map(async (user) => {
            return {
                id: user.id,
                username: user.username,
                email: user.email,
            };
        }));

        return result;
    }



}