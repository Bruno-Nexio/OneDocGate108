// utils.js

function extractUserNameFromAuthHeader(headers) {
  const authHeader = headers['authorization'] || headers['Authorization'];
  if (!authHeader) return null;

  // Si c'est un token de type "Basic base64(user:password)"
  if (authHeader.startsWith('Basic ')) {
    try {
      const base64Credentials = authHeader.split(' ')[1];
      const decoded = Buffer.from(base64Credentials, 'base64').toString('utf-8');
      const [username] = decoded.split(':');
      return username;
    } catch (e) {
      return null;
    }
  }

  // Si c'est un token "Bearer" (ex: JWT), tu peux extraire depuis le payload
  if (authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.split(' ')[1];
      const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString('utf-8'));
      return payload.username || payload.sub || null;
    } catch (e) {
      return null;
    }
  }

  return null;
}

module.exports = {
  extractUserNameFromAuthHeader,
};
