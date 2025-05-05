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
      querystring: querySchema,
      params: paramsSchema
    }
  }, async (request, reply) => {
    const { calendarId } = request.params;
    const { fromDateTime, untilDateTime } = request.query;

    let from = new Date(fromDateTime);
    let until = new Date(untilDateTime);

    if (isNaN(from.getTime()) || isNaN(until.getTime())) {
      return reply.code(400).send({
        code: 2035,
        message: "Invalid date"
      });
    }

    const results = await fastify.mongo.db.collection('events').find({
      calendarId: parseInt(calendarId),
      startDateTime: { $gte: from },
      endDateTime: { $lte: until }
    }).toArray();

    const formatted = results.map(event => {
      return {
        id: event._id.toString(),
        startDateTime: event.startDateTime.toISOString().slice(0, 19),
        endDateTime: event.endDateTime.toISOString().slice(0, 19),
        summary: event.summary || undefined,
        description: event.comment || undefined,
        recurrenceMasterId: event.recurrenceMasterId || undefined
      };
    });

    return reply.code(200).send(formatted);
  });

}

// CommonJs
module.exports = routes
