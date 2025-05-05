// create-event.js

async function routes(fastify, options) {
  const eventSchema = {
    body: {
      type: "object",
      properties: {
        startDateTime: { type: "string" },
        endDateTime: { type: "string" },
        patient: { type: "object" },
        appointmentType: { type: "object" },
        comment: { type: "string" },
        summary: { type: "string" }
      },
      required: ["startDateTime", "endDateTime", "patient", "appointmentType"]
    },
    params: {
      type: "object",
      properties: {
        calendarId: { type: "integer" }
      },
      required: ["calendarId"]
    }
  };

  fastify.post('/calendars/:calendarId/events', { schema: eventSchema }, async (request, reply) => {
    const { calendarId } = request.params;
    const { startDateTime, endDateTime, patient, appointmentType, comment, summary } = request.body;
    const db = fastify.mongo.db;

    const { getNextSequence } = require('../utils/sequence');
    const { extractUserNameFromAuthHeader } = require('../utils/basicAuth');

    const username = extractUserNameFromAuthHeader(request.headers);
    //console.log('User:', username);

    const source = {
       ip: request.headers['x-real-ip'],
       hostname: request.headers['host'],
       userAgent: request.headers['user-agent'] || '',
       user: username || null
    };

    const newEvent = {
      calendarId: parseInt(calendarId),
      startDateTime: new Date(startDateTime),
      endDateTime: new Date(endDateTime),
      patient,
      appointmentType,
      comment: comment || "",
      summary: summary || "",
      source,
      createdAt: new Date()
    };

    try {
      const result = await db.collection('events').insertOne(newEvent);
      const insertedId = result.insertedId.toString();

      // Récupérer un changeId auto-incrémenté
      const changeId = await getNextSequence(fastify, 'onedocChangeId');

      // Insérer une trace dans la collection "changes"
      await db.collection('changes').insertOne({
        changeId,
        action: "created",
        calendarId: parseInt(calendarId),
        eventId: insertedId,
        recurring: false, // à adapter selon la logique si besoin
        timestamp: new Date()
      });

      return reply.code(201).send({
        id: insertedId,
        startDateTime,
        endDateTime,
        description: comment || ""
      });

    } catch (err) {
      request.log.error(err);
      return reply.code(500).send({
        code: 2035,
        message: "Erreur lors de la création de l'événement"
      });
    }
  });
}

module.exports = routes;
