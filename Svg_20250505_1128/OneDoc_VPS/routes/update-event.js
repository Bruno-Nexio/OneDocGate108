// update-event.js

/**
 * Encapsulates the update route
 * @param {FastifyInstance} fastify  Encapsulated Fastify Instance
 * @param {Object} options plugin options
 */

const { ObjectId } = require('mongodb');

async function routes(fastify, options) {

  const updateEventSchema = {
    body: {
      type: "object",
      properties: {
        startDateTime: {
          type: "string",
          pattern: "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{3})?(?:Z)?$"
        },
        endDateTime: {
          type: "string",
          pattern: "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{3})?(?:Z)?$"
        },
        patient: {
          type: "object",
          properties: {
            id: { type: "string" },
            firstName: { type: "string" },
            lastName: { type: "string" },
            gender: { type: "string", enum: ["male", "female", "other"] },
            birthDate: { type: "string", format: "date" },
            email: { type: "string", format: "email" },
            mobilePhoneNumber: { type: "string" },
            insuranceCardNumber: { type: "string" },
            address: {
              type: "object",
              properties: {
                street: { type: "string" },
                streetNumber: { type: "string" },
                zipCode: { type: "string" },
                city: { type: "string" },
                state: { type: "string" },
                country: { type: "string" }
              },
              required: ["street", "streetNumber", "zipCode", "city", "state", "country"]
            }
          },
          required: ["id", "firstName", "lastName", "gender", "birthDate", "email", "mobilePhoneNumber", "insuranceCardNumber", "address"]
        },
        appointmentType: {
          type: "object",
          properties: {
            id: { type: "integer" },
            name: { type: "string" }
          },
          required: ["id", "name"]
        },
        comment: { type: "string" },
        summary: { type: "string" }
      },
      additionalProperties: false
    },
    params: {
      type: "object",
      properties: {
        calendarId: { type: "integer" },
        id: { type: "string", minLength: 24, maxLength: 24 }
      },
      required: ["calendarId", "id"]
    }
  };

  fastify.put('/calendars/:calendarId/events/:id', {
    schema: updateEventSchema
  }, async (request, reply) => {
    const { calendarId, id } = request.params;
    const {
      startDateTime,
      endDateTime,
      patient,
      appointmentType,
      comment,
      summary
    } = request.body;

    const db = fastify.mongo.db;
    const { getNextSequence } = require('../utils/sequence');

    if (!ObjectId.isValid(id)) {
      return reply.code(400).send({ code: 2035, message: "Invalid ID" });
    }

    const updateFields = {
      ...(startDateTime && { startDateTime: new Date(startDateTime) }),
      ...(endDateTime && { endDateTime: new Date(endDateTime) }),
      ...(patient && { patient }),
      ...(appointmentType && { appointmentType }),
      ...(comment && { comment }),
      ...(summary && { summary }),
      updatedAt: new Date()
    };

    try {
      const result = await db.collection('events').findOneAndUpdate(
        { _id: new ObjectId(id), calendarId: parseInt(calendarId) },
        { $set: updateFields },
        { returnDocument: 'after' }
      );

      // Récupérer un changeId auto-incrémenté
      const changeId = await getNextSequence(fastify, 'onedocChangeId');

      // Insérer une trace dans la collection "changes"
      await db.collection('changes').insertOne({
        changeId,
        action: "updated",
        calendarId: parseInt(calendarId),
        eventId: id,
        recurring: false, // à adapter selon la logique si besoin
        timestamp: new Date()
      });

      if (!result) {
        return reply.code(404).send({ code: 404, message: "Événement non trouvé" });
      }

      return reply.code(200).send({
        id: result._id.toString(),
        startDateTime: result.startDateTime.toISOString().slice(0, 19),
        endDateTime: result.endDateTime.toISOString().slice(0, 19),
        description: result.comment || ""
      });

    } catch (err) {
      request.log.error(err);
      return reply.code(500).send({
        code: 2036,
        message: "Erreur lors de la mise à jour de l'événement"
      });
    }
  });
}

// CommonJs
module.exports = routes;

