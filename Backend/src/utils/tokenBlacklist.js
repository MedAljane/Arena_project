const revoked = new Set();
module.exports = {
  
  revoke(token, ttlMs = 0) {
    revoked.add(token);
    if (ttlMs > 0) setTimeout(() => revoked.delete(token), ttlMs);
  },
  
  isRevoked(token) {
    return revoked.has(token);
  },
};