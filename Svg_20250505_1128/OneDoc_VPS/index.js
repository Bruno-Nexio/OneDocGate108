const Fastify = require('fastify');
const fastify = Fastify({ logger: true });
const dayjs = require('dayjs')
const path = require('path')
const compress = require('@fastify/compress');
const PORT = parseInt(process.env.PORT, 10) || 8082;
const HOST = process.env.HOST || '0.0.0.0';

// Enregistrer le plugin de compression
//fastify.register(compress, { global: true, encodings: ['gzip','defalte'] });  // Compresse toutes les réponses par défaut
// On enregistre le connecteur a mongodb
fastify.register(require('./connector/mongodb'))
// On enregistre les routes

// Get the version of the API
fastify.register(require('./routes/get-version'))

// Return the list of events occurring within the provided datetime interval. 
fastify.register(require('./routes/get-events'))

// Return the information of the event associated to the given ID
fastify.register(require('./routes/get-event'))

// Creates a new event and return it
fastify.register(require('./routes/create-event'))

// Updates an existing event and return its information
fastify.register(require('./routes/update-event'))

// Delete an existing event and return a 204 no-content
fastify.register(require('./routes/delete-event'))

// Get the latest change Id
fastify.register(require('./routes/last-change-id'))

// Get the events changes
fastify.register(require('./routes/get-event-changes'))

// Test the mongoDB connection
fastify.register(require('./routes/test-mongodb'))

// Fastify fournit un hook setErrorHandler pour capturer toutes les erreurs et personnaliser la réponse:
fastify.setErrorHandler((error, request, reply) => {
  if (error.validation) {
    const invalidField = error.validation[0].instancePath.replace("/", "")
    if (invalidField === "fromDateTime" || invalidField === "untilDateTime") {
      return reply.status(400).send({
        code: 2035,
        message: "Invalid date"
      })
    }
  }

  reply.status(error.statusCode || 500).send({
    code: error.statusCode || 500,
    message: error.message
  })
})

fastify.listen({ host: HOST, port: PORT }, (err, address) => {
    if (err) {
        console.error(err)
        process.exit(1)
    }
});
