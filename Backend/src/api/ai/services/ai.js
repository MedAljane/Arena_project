'use strict';


const { generateText }      = require('ai');
const { getModel }          = require('./provider');
const { buildPlayerTools }  = require('./player-tools');
const { buildManagerTools } = require('./manager-tools');
const { logTurn }           = require('../../ai-log/services/ai-log');

// ── System prompts ────────────────────────────────────────────────────────────

const PLAYER_SYSTEM = `
You are Arena AI, an intelligent sports booking assistant for the Arena platform.
You help players find available terrain slots and book them automatically.

How you work:
1. When the player asks for a slot, call getAvailableSlotsForDate to search.
2. Pick the best match (closest to preferred time, available campus).
3. Call bookReservation to book it immediately — do not ask for confirmation.
4. Report clearly what you booked: campus name, terrain type, date, time.

If no slot matches the criteria, report that clearly and suggest alternatives.
Use getMyReservations to answer questions about existing bookings.
Use cancelReservation only when the player explicitly asks to cancel.

Be concise. Use plain language. No markdown. Today's date: ${new Date().toISOString().split('T')[0]}
`.trim();

const MANAGER_SYSTEM = `
You are Arena AI, an intelligent assistant for Arena campus managers.
You help managers create schedules, manage agendas, and handle reservations.

Your capabilities:
- getMyTerrains: list terrains to know IDs before creating agendas
- createWeekAgenda: create a week agenda (auto-generates 7 day plans + default slots)
- publishAgenda: make an agenda visible to players — always publish after creating
- getAgendaDetails: inspect day plans and slots of an existing agenda
- setDayPlanType: change a day to day_off, normal, or urgent_only
- deleteTimeSlot: remove a slot (use after setting a day to day_off)
- createTimeSlot: add a slot to a day plan
- getPendingReservations: list unconfirmed bookings
- getReservationById: look up a single reservation by its ID with full details
- getReservationsByDate: list all reservations on a given date (YYYY-MM-DD), filter by status
- confirmReservation: approve a pending booking
- cancelReservation: cancel any booking (pending or confirmed) — frees the slot
- deleteAgenda: permanently remove an agenda

IMPORTANT RULES:
- Week agendas always start on MONDAY. Compute the correct Monday for each week.
- After creating agendas, always call publishAgenda for each one (unless told not to).
- If a day plan has dayType='day_off', delete ALL its time slots immediately.
- Do not ask the manager to confirm multi-step operations — execute them in order.
- After bulk operations, give a concise summary (e.g., "Created and published 4 agendas. Cleaned 8 slots from day_off days.").

Be concise. Use plain language. No markdown. Today's date: ${new Date().toISOString().split('T')[0]}
`.trim();

// ── Helpers ───────────────────────────────────────────────────────────────────

function extractToolCalls(result) {
    return (result.steps || [])
        .flatMap((step) => step.toolCalls || [])
        .map((tc) => ({ tool: tc.toolName, params: tc.args }));
}

function totalTokens(result) {
    const u = result.usage || {};
    return (u.promptTokens || 0) + (u.completionTokens || 0);
}

// ── Core chat functions ───────────────────────────────────────────────────────

/**
 * Run a player chat turn.
 * @param {number} playerAuthId
 * @param {string} message
 * @param {{ role: 'user'|'assistant', content: string }[]} history
 * @param {string} [sessionId] - UUID grouping this conversation
 */
async function playerChat(playerAuthId, message, history = [], sessionId = '') {
    const model    = getModel();
    const tools    = buildPlayerTools(playerAuthId);
    const messages = [...history, { role: 'user', content: message }];
    const start    = Date.now();

    let result, actionsPerformed, success = true, errorMessage = null;

    try {
        result           = await generateText({ model, system: PLAYER_SYSTEM, messages, tools, maxSteps: 8 });
        actionsPerformed = extractToolCalls(result);
    } catch (err) {
        success      = false;
        errorMessage = err.message;
        // Re-throw so the controller returns an error to the client
        throw err;
    } finally {
        // Always log — even on error (success=false captures the failure)
        await logTurn({
            userAuthId:   playerAuthId,
            userRole:     'player',
            provider:     process.env.LLM_PROVIDER || 'gemini',
            model:        String(model),
            userMessage:  message,
            aiReply:      result?.text || '',
            toolsUsed:    actionsPerformed || [],
            actionsTaken: actionsPerformed || [],
            tokensUsed:   result ? totalTokens(result) : 0,
            processingMs: Date.now() - start,
            success,
            errorMessage,
            sessionId,
        });
    }

    return { reply: result.text, actionsPerformed };
}

/**
 * Run a manager chat turn.
 * @param {number} managerAuthId
 * @param {string} message
 * @param {{ role: 'user'|'assistant', content: string }[]} history
 * @param {string} [sessionId]
 */
async function managerChat(managerAuthId, message, history = [], sessionId = '') {
    const model    = getModel();
    const tools    = buildManagerTools(managerAuthId);
    const messages = [...history, { role: 'user', content: message }];
    const start    = Date.now();

    let result, actionsPerformed, success = true, errorMessage = null;

    try {
        result           = await generateText({ model, system: MANAGER_SYSTEM, messages, tools, maxSteps: 20 });
        actionsPerformed = extractToolCalls(result);
    } catch (err) {
        success      = false;
        errorMessage = err.message;
        throw err;
    } finally {
        await logTurn({
            userAuthId:   managerAuthId,
            userRole:     'manager',
            provider:     process.env.LLM_PROVIDER || 'gemini',
            model:        String(model),
            userMessage:  message,
            aiReply:      result?.text || '',
            toolsUsed:    actionsPerformed || [],
            actionsTaken: actionsPerformed || [],
            tokensUsed:   result ? totalTokens(result) : 0,
            processingMs: Date.now() - start,
            success,
            errorMessage,
            sessionId,
        });
    }

    return { reply: result.text, actionsPerformed };
}

module.exports = { playerChat, managerChat };
