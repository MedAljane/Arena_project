'use strict';

/**
 * ai-assisstant-config service
 */

const { createCoreService } = require('@strapi/strapi').factories;

const DEFAULTS = {
    Player: {
        provider:    'gemini',
        model:       'gemini-2.5-flash',
        temperature: 0.7,
        maxTokens:   1024,
        maxSteps:    8,
    },
    Manager: {
        provider:    'gemini',
        model:       'gemini-2.5-flash',
        temperature: 0.7,
        maxTokens:   2048,
        maxSteps:    20,
    },
};

const ADVANCED_FIELDS = [
    'topP', 'topK', 'presencePenalty', 'frequencyPenalty',
    'stopSequences', 'seed', 'maxRetries', 'toolChoice',
];

module.exports = createCoreService('api::ai-assisstant-config.ai-assisstant-config', () => ({

    /**
     * Resolve the active config for a role ('Player' | 'Manager').
     * Falls back to hardcoded defaults for any field that is missing —
     * either because no row exists yet, or it was left blank in the admin panel.
     * Advanced fields are only included when explicitly set.
     */
    async getConfigForRole(role) {
        const row = await strapi.db
            .query('api::ai-assisstant-config.ai-assisstant-config')
            .findOne({ where: { assisstant_config_for: role } });

        const fallback = DEFAULTS[role] || DEFAULTS.Player;
        const config = {
            provider:    row?.provider    ?? fallback.provider,
            model:       row?.model       ?? fallback.model,
            temperature: row?.temperature ?? fallback.temperature,
            maxTokens:   Number(row?.maxTokens ?? fallback.maxTokens),
            maxSteps:    row?.maxSteps    ?? fallback.maxSteps,
        };

        for (const field of ADVANCED_FIELDS) {
            const value = row?.[field];
            if (value !== null && value !== undefined) config[field] = value;
        }

        return config;
    },
}));
