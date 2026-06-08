'use strict';

module.exports = {

    
    async findLogs(ctx) {
        try {
            const page     = parseInt(ctx.query.page  || '1',  10);
            const pageSize = parseInt(ctx.query.limit || '50', 10);
            const search   = ctx.query.search || '';
            const role     = ctx.query.role   || '';
            const onlyErrors = ctx.query.errors === 'true';

            const where = {};
            if (role)       where.userRole = role;
            if (onlyErrors) where.success  = false;
            if (search)     where.userMessage = { $containsi: search };

            const db = strapi.db.query('api::ai-assisstant-chat-log.ai-assisstant-chat-log');
            const [logs, total] = await Promise.all([
                db.findMany({
                    where,
                    populate: { userId: { select: ['id', 'username', 'email'] } },
                    orderBy:  { createdAtTimestamp: 'desc' },
                    limit:    pageSize,
                    offset:   (page - 1) * pageSize,
                }),
                db.count({ where }),
            ]);

            ctx.send({ data: logs, meta: { total, page, pageSize } });
        } catch (err) {
            console.error('[ai-assisstant-chat-log] findLogs error:', err);
            ctx.badRequest(err.message);
        }
    },

    
    async stats(ctx) {
        try {
            const db = strapi.db.query('api::ai-assisstant-chat-log.ai-assisstant-chat-log');

            // ── Aggregate counts ──────────────────────────────────────────────

            const [total, playerTotal, managerTotal, successCount, errorCount] =
                await Promise.all([
                    db.count({}),
                    db.count({ where: { userRole: 'player'  } }),
                    db.count({ where: { userRole: 'manager' } }),
                    db.count({ where: { success: true  } }),
                    db.count({ where: { success: false } }),
                ]);

            // ── All logs for heavy aggregation ────────────────────────────────
            const logs = await db.findMany({
                select: [
                    'userRole', 'provider', 'tokensUsed', 'processingMs',
                    'toolsUsed', 'success', 'createdAtTimestamp',
                ],
                orderBy: { createdAtTimestamp: 'desc' },
            });

            // ── Tokens & latency ──────────────────────────────────────────────
            const tokenValues = logs.map((l) => Number(l.tokensUsed) || 0);
            const msValues    = logs.map((l) => Number(l.processingMs) || 0);

            const avg = (arr) =>
                arr.length === 0 ? 0 : Math.round(arr.reduce((a, b) => a + b, 0) / arr.length);

            // ── Provider breakdown ────────────────────────────────────────────
            const byProvider = {};
            for (const l of logs) {
                const p = l.provider || 'unknown';
                byProvider[p] = (byProvider[p] || 0) + 1;
            }

            // ── Tool usage frequency ──────────────────────────────────────────
            const toolFreq = {};
            for (const l of logs) {
                const tools = Array.isArray(l.toolsUsed) ? l.toolsUsed : [];
                for (const t of tools) {
                    const name = t?.tool || t?.toolName || String(t);
                    toolFreq[name] = (toolFreq[name] || 0) + 1;
                }
            }
            const topTools = Object.entries(toolFreq)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 10)
                .map(([tool, count]) => ({ tool, count }));

            // ── Daily activity (last 30 days) ─────────────────────────────────
            const cutoff = new Date();
            cutoff.setDate(cutoff.getDate() - 30);

            const dailyMap = {};
            for (const l of logs) {
                const ts = l.createdAtTimestamp
                    ? new Date(l.createdAtTimestamp)
                    : null;
                if (!ts || ts < cutoff) continue;
                const day = ts.toISOString().split('T')[0];
                if (!dailyMap[day]) dailyMap[day] = { total: 0, player: 0, manager: 0 };
                dailyMap[day].total++;
                if (l.userRole === 'player')  dailyMap[day].player++;
                if (l.userRole === 'manager') dailyMap[day].manager++;
            }
            const dailyActivity = Object.entries(dailyMap)
                .sort(([a], [b]) => a.localeCompare(b))
                .map(([date, counts]) => ({ date, ...counts }));

            // ── Booking conversion (player only) ──────────────────────────────
            const playerLogs         = logs.filter((l) => l.userRole === 'player');
            const sessionsWithBooking = new Set(
                playerLogs
                    .filter((l) =>
                        Array.isArray(l.toolsUsed) &&
                        l.toolsUsed.some((t) => (t?.tool || '') === 'bookReservation'))
                    .map((l) => l.sessionId)
            ).size;
            const totalPlayerSessions = new Set(
                playerLogs.map((l) => l.sessionId).filter(Boolean)
            ).size;

            ctx.send({
                overview: {
                    total,
                    playerTotal,
                    managerTotal,
                    successCount,
                    errorCount,
                    successRate: total === 0
                        ? 0
                        : Math.round((successCount / total) * 100),
                },
                performance: {
                    avgTokensPerTurn:  avg(tokenValues),
                    avgProcessingMs:   avg(msValues),
                    totalTokensUsed:   tokenValues.reduce((a, b) => a + b, 0),
                },
                byProvider,
                topTools,
                dailyActivity,
                conversion: {
                    totalPlayerSessions,
                    sessionsWithBooking,
                    bookingConversionPct: totalPlayerSessions === 0
                        ? 0
                        : Math.round((sessionsWithBooking / totalPlayerSessions) * 100),
                },
            });
        } catch (err) {
            console.error('[ai-assisstant-chat-log] stats error:', err);
            ctx.badRequest(err.message);
        }
    },
};
