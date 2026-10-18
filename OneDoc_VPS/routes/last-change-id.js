// last-change-id.js

/**
 * Encapsulates the routes
 * @param {FastifyInstance} fastify  Encapsulated Fastify Instance
 * @param {Object} options plugin options, refer to https://fastify.dev/docs/latest/Reference/Plugins/#plugin-options
 */

const { peekNextSequence } = require('../utils/sequence'); // adapte le chemin selon ton projet

async function routes(fastify, options) {
  fastify.get('/events/last-change-id', async (request, reply) => {
    try {
      const changeId = await peekNextSequence(fastify, 'onedocChangeId');

      // Vérification basique pour s'assurer que le changeId est bien un nombre
      if (typeof changeId !== 'number' || isNaN(changeId)) {
        return reply.code(400).send({
          code: 2035,
          message: 'Invalid date'
        });
      }

      return reply.code(200).send({
        changeId
      });

    } catch (err) {
      // Catch général au cas où la requête vers MongoDB échoue
      return reply.code(400).send({
        code: 2035,
        message: 'Invalid date'
      });
    }
  });
}

// CommonJs
module.exports = routes
