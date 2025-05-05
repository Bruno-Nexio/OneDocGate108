// delete-event.js

/**
 * Encapsulates the delete route
 * @param {FastifyInstance} fastify
 * @param {Object} options
 */

const { ObjectId } = require('mongodb');

async function routes(fastify, options) {
  const deleteEventSchema = {
    params: {
      type: "object",
      properties: {
        calendarId: { type: "integer" },
        id: { type: "string", minLength: 24, maxLength: 24 }
      },
      required: ["calendarId", "id"]
    }
  };

  fastify.delete('/calendars/:calendarId/events/:id', {
    schema: deleteEventSchema
  }, async (request, reply) => {
    const { calendarId, id } = request.params;
    const db = fastify.mongo.db;
    const { getNextSequence } = require('../utils/sequence');

    if (!ObjectId.isValid(id)) {
      return reply.code(400).send({ code: 2035, message: "Invalid ID" });
    }

    try {
      const result = await db.collection('events').deleteOne({
        _id: new ObjectId(id),
        calendarId: parseInt(calendarId)
      });

      // Récupérer un changeId auto-incrémenté
      const changeId = await getNextSequence(fastify, 'onedocChangeId');

      // Insérer une trace dans la collection "changes"
      await db.collection('changes').insertOne({
        changeId,
        action: "deleted",
        calendarId: parseInt(calendarId),
        eventId: id,
        recurring: false, // à adapter selon la logique si besoin
        timestamp: new Date()
      });

      if (result.deletedCount === 0) {
        return reply.code(404).send({
          code: 404,
          message: "Événement non trouvé ou déjà supprimé"
        });
      }

      return reply.code(204).send();

    } catch (err) {
      request.log.error(err);
      return reply.code(500).send({
        code: 2037,
        message: "Erreur lors de la suppression de l'événement"
      });
    }
  });
}

// CommonJs
module.exports = routes;
