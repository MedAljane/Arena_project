const firebaseService = require('../../../../firebase/firebase.service');

async function handleConfirmed(reservationId) {
    try {
        const reservation = await strapi.db
            .query('api::reservation.reservation')
            .findOne({
                where: { id: reservationId },
                populate: ['player', 'terrain'],
            });

        const { player, terrain } = reservation;

        if (!player || !terrain) {
            console.error(`Player or Terrain not found for reservation ID: ${reservationId}`);
            return;
        }

        const terrainWithEmployee = await strapi.db.query('api::terrain.terrain').findOne({
            where: { id: terrain.id || terrain },
            populate: ['employee'],
        });

        const employee = terrainWithEmployee?.employee;
        if (!employee) {
            console.warn(`No employee assigned to terrain ${terrain.id || terrain}. Skipping conversation.`);
            return;
        }

        if (!player.firebaseUid) {
            player.firebaseUid = `player-${player.id}`;
            player.fcmToken    = `fcm-player-${player.id}`;
            player.nom         = player.nom || `Player ${player.id}`;
            await strapi.db.query('api::player.player').update({
                where: { id: player.id },
                data: { firebaseUid: player.firebaseUid, fcmToken: player.fcmToken, nom: player.nom }
            });
        }

        if (!employee.firebaseUid) {
            employee.firebaseUid = `employee-${employee.id}`;
            employee.fcmToken    = `fcm-employee-${employee.id}`;
            employee.nom         = employee.nom || `Employee ${employee.id}`;
            await strapi.db.query('api::employee.employee').update({
                where: { id: employee.id },
                data: { firebaseUid: employee.firebaseUid, fcmToken: employee.fcmToken, nom: employee.nom }
            });
        }

        const playerUid   = player.firebaseUid;
        const employeeUid = employee.firebaseUid;

        await firebaseService.createConversation({
            reservationId,
            playerUid,
            employeeUid,
            playerId:     player.id,
            employeeId:   employee.id,
            playerName:   player.nom,
            employeeName: employee.nom,
            terrainType:  terrainWithEmployee.Type,
        });

        console.log(`Conversation (player ↔ employee) created for reservation ID: ${reservationId}`);
    } catch (error) {
        console.error(`Error creating conversation for reservation ID: ${reservationId}`, error);
    }
}

module.exports = {
    async afterCreate({ result }) {
        // Reservations start as 'pending' — no conversation yet.
        if (result.statu !== 'confirmed') return;
        await handleConfirmed(result.id);
    },

    async afterUpdate({ result }) {
        // Manager confirmed the reservation → create conversation.
        if (result.statu !== 'confirmed') return;
        await handleConfirmed(result.id);
    },
};
