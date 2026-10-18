// get-version.js

/**
 * Encapsulates the routes
 * @param {FastifyInstance} fastify  Encapsulated Fastify Instance
 * @param {Object} options plugin options, refer to https://fastify.dev/docs/latest/Reference/Plugins/#plugin-options
 */

async function routes (fastify, options) {

fastify.get('/version', function handler (request, reply) {
      reply.send({ version: '1.0.8' })
    })

}
// CommonJs
module.exports = routes
