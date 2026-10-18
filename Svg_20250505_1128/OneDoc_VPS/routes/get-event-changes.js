/**
 * Encapsulates the routes
 * @param {FastifyInstance} fastify  Encapsulated Fastify Instance
 * @param {Object} options plugin options
 */

const querySchema = {
  type: 'object',
  properties: {
    afterChangeId: { type: 'integer' }
  },
  required: ['afterChangeId']
};

async function routes(fastify, options) {
  fastify.get('/events/changes', {
    schema: {
      querystring: querySchema,
      response: {
        200: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              changeId: { type: 'integer' },
              action: { type: 'string' },
              calendarId: { type: 'integer' },
              eventId: { type: 'string' },
              recurring: { type: 'boolean' }
            },
            required: ['changeId', 'action', 'calendarId', 'eventId', 'recurring']
          }
        },
        400: {
          type: 'object',
          properties: {
            code: { type: 'integer' },
            message: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const db = fastify.mongo.db;
    const { afterChangeId } = request.query;

    if (typeof afterChangeId !== 'number' || afterChangeId < 0) {
      return reply.code(400).send({
        code: 4001,
        message: 'Paramètre afterChangeId invalide ou manquant'
      });
    }

    try {
      const changes = await db.collection('changes')
        .find({ changeId: { $gt: afterChangeId } }, { projection: { _id: 0 } })
        .sort({ changeId: 1 })
        .toArray();

      return reply.code(200).send(changes);
    } catch (err) {
      request.log.error(err);
      return reply.code(500).send({
        code: 5002,
        message: "Erreur lors de la récupération des changements"
      });
    }
  });
}

module.exports = routes;
