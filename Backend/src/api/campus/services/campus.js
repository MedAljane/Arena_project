const manager = require("../../manager/services/manager");
const axios = require("axios");

// @ts-ignore
async function getCoordsFromAddress(address) {
    const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(address)}&format=json&limit=1`;

    const response = await axios.get(url,
        {
            headers: {
                'User-Agent': 'ArenaApp/1.0 (contact: aljane.medamine.97@gmail.com)'
            }
        }
    );

    const data = response.data;

    if (!data || data.length === 0) {
        throw new Error('Unable to geocode address');
    }

    return {
        lat: data[0].lat,
        long: data[0].lon
    };
}

module.exports = {

    // @ts-ignore
    async createCampus(name, description, address, phone, nbTerrains, mainImage, galleryImages, managerId) {
        // @ts-ignore
        const { lat, long } = await getCoordsFromAddress(address);
        console.log(`Geocoded address: ${address} -> lat: ${lat}, long: ${long}`);

        try {
            const result = await strapi.entityService.create('api::campus.campus', {
                data: {
                    Name: name,
                    Description: description,
                    Address: address,
                    phone,
                    NbTerrains: nbTerrains || 0,
                    Long: long,
                    Lat: lat,
                    manager: {
                        connect: [{ id: managerId }]
                    },
                    main_image: mainImage || null,
                    gallery: galleryImages || [],
                    publishedAt: new Date(),
                },
                populate: ['main_image', 'gallery', 'manager']
            });

            return result;
        } catch (err) {
            console.error('Error creating campus:', err);
            throw new Error('Failed to create campus');
        };
    },

    // @ts-ignore
    async updateCampus(id, data) {
            const campus = await strapi.db.query('api::campus.campus').findOne({ where: { id } });

            if (!campus) {
                throw new Error('Campus not found');
            }

            const updatedData = { ...data , publishedAt: new Date() };

            let coords = { lon: campus.long, lat: campus.lat };
            if (data.address && data.address !== campus.address) {
                const { lat, long } = await getCoordsFromAddress(data.address);
                updatedData.long = long;
                updatedData.lat = lat;
            }

            if (data.mainImage !== undefined) {
                updatedData.main_image = {id: data.mainImage};
            }

            if (data.galleryImages && Array.isArray(data.galleryImages)) {
                updatedData.gallery = {
                    // @ts-ignore
                    set: data.galleryImages.map(id => ({ id }))
                };
            }

            return await strapi.entityService.update('api::campus.campus', id, {
                data: updatedData,
                populate: ['main_image', 'gallery', 'manager']
            });
        },

    // @ts-ignore
    async deleteCampus(id) {
            const campus = await strapi.db.query('api::campus.campus').findOne({ where: { id } });

            if (!campus) {
                throw new Error('Campus not found');
            }

            try {
                await strapi.entityService.delete('api::campus.campus', id);
            } catch (err) {
                console.error('Error deleting campus:', err);
                throw new Error('Failed to delete campus');
            }

            return { message: `Campus with ID ${id} deleted successfully` };
        },

    // @ts-ignore
    async getCampuses() {
            return await strapi.db.query('api::campus.campus').findMany({
                populate: ['main_image', 'gallery', 'manager']
            });

        },

    // @ts-ignore
    async getCampusByManager(managerId) {
            return await strapi.db.query('api::campus.campus').findMany({
                where: { manager: managerId },
                populate: ['main_image', 'gallery', 'manager']
            });
        },

    // @ts-ignore
    async getCampusById(id) {
            const campus = await strapi.db.query('api::campus.campus').findOne({
                where: { id },
                populate: ['main_image', 'gallery', 'manager']
            });
            return campus;
        },

    }