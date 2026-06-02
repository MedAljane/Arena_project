const revoked = new Set();
module.exports = {
  // @ts-ignore
  revoke(token, ttlMs = 0) {
    revoked.add(token);
    if (ttlMs > 0) setTimeout(() => revoked.delete(token), ttlMs);
  },
  // @ts-ignore
  isRevoked(token) {
    return revoked.has(token);
  },
};