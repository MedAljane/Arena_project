'use strict';

module.exports = async (policyContext, config, { strapi }) => {
    const user = policyContext.state.user;
    if (!user) return false;
    return user.user_role === 'employee';
};
