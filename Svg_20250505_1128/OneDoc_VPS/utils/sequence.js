/**
 * Récupère et incrémente le compteur pour un identifiant donné.
 * @param {FastifyInstance} fastify
 * @param {string} name - Nom du compteur
 * @returns {Promise<number>} - Valeur incrémentée
 */
async function getNextSequence(fastify, name) {
  const result = await fastify.mongo.db.collection('counters').findOneAndUpdate(
    { _id: name },
    { $inc: { sequence_value: 1 } },
    {
      returnDocument: 'after',
      upsert: true
    }
  );

  return result.sequence_value;
}

/**
 * Regarde la prochaine valeur du compteur sans l’incrémenter.
 * @param {FastifyInstance} fastify
 * @param {string} name - Nom du compteur
 * @returns {Promise<number>} - Valeur actuelle (non incrémentée)
 */
async function peekNextSequence(fastify, name) {
  const result = await fastify.mongo.db.collection('counters').findOne({ _id: name });

  // Si le compteur n'existe pas encore, retourner 1 comme prochaine valeur attendue
  return result?.sequence_value ?? 1;
}

module.exports = {
  getNextSequence,
  peekNextSequence
};
