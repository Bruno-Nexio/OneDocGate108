module.exports = {
  apps: [
    {
      name: "onedoc-api",          // Nom de l'app
      script: "./index.js",        // Fichier de démarrage
      watch: true,                 // Redémarrage automatique si fichiers modifiés
      ignore_watch: [              // Fichiers/dossiers à ignorer
        "node_modules",
        "logs",
        ".git",
        "ecosystem.config.js"
      ],
      instances: 1,                // Nombre d'instances (1 pour dev)
      autorestart: true,
      max_memory_restart: "300M",  // Redémarrage si mémoire dépasse 300MB
      env: {
        NODE_ENV: "development"
      },
      env_production: {
        NODE_ENV: "production"
      }
    }
  ]
};
