'use strict';

module.exports = {
  /**
   * An asynchronous register function that runs before
   * your application is initialized.
   *
   * This gives you an opportunity to extend code.
   */
  register(/*{ strapi }*/) {},

  /**
   * An asynchronous bootstrap function that runs before
   * your application gets started.
   *
   * This gives you an opportunity to set up your data model,
   * run jobs, or perform some special logic.
   */
  
  async bootstrap({ strapi }) {
    const exist = await strapi.db.query('plugin::users-permissions.user').findOne({ 
      where : {
        email: process.env.ADMIN_EMAIL
      }
    });

    if (!exist) {
      const role = await strapi.db.query('plugin::users-permissions.role').findOne({ where: { type: 'authenticated' } });

      const user = await strapi.plugins['users-permissions'].services.user.add({
        username: process.env.ADMIN_USERNAME,
        email: process.env.ADMIN_EMAIL,
        password: process.env.ADMIN_PASSWORD,
        role: role.id,
        user_role: 'admin'
      });

      console.log('Admin user created!');
    } else {
      console.log('Admin user already exists!');
    }

  }
};
