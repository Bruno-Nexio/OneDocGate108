// get-events.js

/**
 * Encapsulates the routes
 * @param {FastifyInstance} fastify  Encapsulated Fastify Instance
 * @param {Object} options plugin options, refer to https://fastify.dev/docs/latest/Reference/Plugins/#plugin-options
 */

const querySchema = {
  "title": "Query Schema",
  "type": "object",
  "properties": {
    "fromDateTime": { "type": "string", pattern: "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{3})?(?:Z)?$" }, // Vérifie que c'est un date-time
    "untilDateTime": { "type": "string", pattern: "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{3})?(?:Z)?$" } // Vérifie que c'est un date-time
  },
  "additionalProperties": false,
  "required": ["fromDateTime", "untilDateTime" ]
}

const paramsSchema = {
  type: "object",
  properties: {
    calendarId: { type: "integer"  } // Vérifie que c'est un entier
  },
  required: ["calendarId"]
}


async function routes (fastify, options) {

    fastify.get('/calendars/:calendarId/events', {
      schema: {
        params: paramsSchema,
        querystring: querySchema
      }
    }, async (request, reply) => {
       const { calendarId } = request.params
       const { fromDateTime, untilDateTime } = request.query


      return { message: `Events for calendar ${calendarId}`, filters: { fromDateTime, untilDateTime } }
    })

    fastify.get('/hello', {
      schema: {
        querystring: querySchema
      }
    }, async (request, reply) => {
      return { hello: 'world' }
    })

    fastify.get('/ciao', {
      schema: {
        querystring: querySchema
      }
    }, async (request, reply) => {
      return { ciao: 'world' }
    })

    fastify.get('/', function handler (request, reply) {
      reply.send({ hello: 'world' })
    })

    fastify.get('/version/', function handler (request, reply) {
      console.log(request.query.test)
      reply.send({ version: '0.01.0', test: request.query.test  })
    })

}

// CommonJs
module.exports = routes
