async function routes(fastify, options) {
    fastify.get('/mongodb', async (request, reply) => {
        try {
            const db = fastify.mongo.db; // Utilise fastify.mongo.db
            const events = db.collection('counters'); // Accès à la collection

            const result = await fastify.mongo.db.collection('counters').findOneAndUpdate(
              { _id: 'onedocChangeId' },
              { $inc: { sequence_value: 1 } },
              {
                returnDocument: 'after', // renvoie le document après mise à jour
                upsert: true             // crée le doc s’il n’existe pas
              }
            );
            console.log(result.sequence_value)
            return { message: "Connexion réussie", collection: events.namespace };
        } catch (error) {
            reply.status(500).send({ error: error.message });
        }
    });
}

module.exports = routes;
