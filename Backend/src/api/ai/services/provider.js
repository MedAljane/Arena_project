'use strict';

/**
 * LLM provider abstraction.
 * Reads LLM_PROVIDER env var and returns the corresponding AI SDK model.
 *
 * Supported values:
 *   gemini  → Google Gemini (default)
 *   openai  → OpenAI GPT-4o
 *   ollama  → Local Ollama via OpenAI-compatible API
 */


const { createOpenAI } = require('@ai-sdk/openai');

const { createGoogleGenerativeAI } = require('@ai-sdk/google');

/**
 * @param {string} [providerOverride] - e.g. from the AI assistant config ('gemini'|'openai'|'ollama')
 * @param {string} [modelOverride]    - e.g. 'gemini-2.5-flash', 'gpt-4o-mini'
 */
function getModel(providerOverride, modelOverride) {
    const provider = (providerOverride || process.env.LLM_PROVIDER || 'gemini').toLowerCase();

    switch (provider) {
        case 'openai': {
            const openai = createOpenAI({ apiKey: process.env.OPENAI_API_KEY });
            return openai(modelOverride || 'gpt-4o-mini');
        }

        case 'ollama': {
            // Ollama exposes an OpenAI-compatible API at /v1
            const ollama = createOpenAI({
                baseURL: process.env.OLLAMA_BASE_URL || 'http://localhost:11434/v1',
                apiKey:  'ollama', // required by the SDK but not used by Ollama
            });
            return ollama(modelOverride || process.env.OLLAMA_MODEL || 'llama3.2');
        }

        case 'gemini':
        default: {
            const google = createGoogleGenerativeAI({ apiKey: process.env.GEMINI_API_KEY });
            return google(modelOverride || 'gemini-2.5-flash');
        }
    }
}

module.exports = { getModel };
