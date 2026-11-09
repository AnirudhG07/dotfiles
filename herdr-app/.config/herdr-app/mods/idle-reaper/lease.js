// "Only one copy acts at a time."
//
// A mod that does something (renames tabs, closes panes) must not do it twice when a layout holds two copies of
// it or the app reloads it. Copies share a lease through the app's shared state: the newest copy takes it, the
// holder renews it, and a lease nobody renewed for `ms` is free for anyone.
//
// Source of truth: copied into each mod by `scripts/sync-shared` (see shared/llm.js for why).

export class Lease {
  /** @param {string} key shared-state key  @param {{shared: Function, setShared: Function}} api  @param {number} ms */
  constructor(key, api, ms = 60000) {
    this.key = key;
    this.api = api;
    this.ms = ms;
    this.id = Math.random().toString(36).slice(2, 10);
    api.setShared(key, { id: this.id, at: Date.now() }); // the newest copy takes over
  }

  /** Whether this copy may act. */
  holds(now = Date.now()) {
    const l = this.api.shared(this.key);
    return !l || l.id === this.id || now - l.at > this.ms;
  }

  /** Renew (or take over a lease nobody renewed). Call it every few seconds. */
  beat(now = Date.now()) {
    const l = this.api.shared(this.key);
    if (!l || l.id === this.id || now - l.at > this.ms) this.api.setShared(this.key, { id: this.id, at: now });
  }

  /** Give the lease up (when the copy closes). */
  release() {
    if (this.api.shared(this.key)?.id === this.id) this.api.setShared(this.key, null);
  }
}
