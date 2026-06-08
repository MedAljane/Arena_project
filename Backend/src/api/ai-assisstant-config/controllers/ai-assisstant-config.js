'use strict';

/**
 * ai-assisstant-config controller
 */

const { createCoreController } = require('@strapi/strapi').factories;

const ROLES = ['Player', 'Manager'];

module.exports = createCoreController('api::ai-assisstant-config.ai-assisstant-config', () => ({

    /** GET /admin/ai-config — current Player & Manager configs (with defaults filled in). */
    async getConfigs(ctx) {
        try {
            const service = strapi.service('api::ai-assisstant-config.ai-assisstant-config');
            const [player, manager] = await Promise.all([
                service.getConfigForRole('Player'),
                service.getConfigForRole('Manager'),
            ]);
            ctx.send({ Player: player, Manager: manager });
        } catch (err) {
            console.error('[ai-assisstant-config] getConfigs error:', err);
            ctx.badRequest(err.message);
        }
    },

    /** PUT /admin/ai-config/:role — create or update the config row for a role. */
    async upsertConfig(ctx) {
        const role = ctx.params.role;
        if (!ROLES.includes(role)) {
            return ctx.badRequest(`role must be one of: ${ROLES.join(', ')}`);
        }

        const { id, assisstant_config_for, ...rest } = ctx.request.body || {};
        const data = { ...rest, assisstant_config_for: role };

        try {
            const db       = strapi.db.query('api::ai-assisstant-config.ai-assisstant-config');
            const existing = await db.findOne({ where: { assisstant_config_for: role } });

            const saved = existing
                ? await db.update({ where: { id: existing.id }, data })
                : await db.create({ data: { ...data, publishedAt: new Date() } });

            ctx.send({ success: true, config: saved });
        } catch (err) {
            console.error('[ai-assisstant-config] upsertConfig error:', err);
            ctx.badRequest(err.message);
        }
    },
}));
