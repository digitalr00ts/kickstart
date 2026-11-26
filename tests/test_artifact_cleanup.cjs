'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const cleanup = require('../scripts/artifact-cleanup.cjs');

const now = Date.parse('2026-11-25T00:00:00Z');
const ago = days => new Date(now - days * 86400000).toISOString();
const artifact = (id, age, name = `fedora-44-x86_64-${id}`) => ({
  id, name, created_at: ago(age), size_in_bytes: 1024,
});

function fixture(artifacts, { eventName = 'workflow_dispatch', inputs = {}, fail = [] } = {}) {
  const deleted = [];
  const outputs = {};
  const tables = [];
  const actions = {
    listArtifactsForRepo: () => { throw new Error('Must paginate, not fetch a single page'); },
    deleteArtifact: async ({ artifact_id: id }) => {
      if (fail.includes(id)) throw new Error('API failure');
      deleted.push(id);
    },
  };
  const summary = {
    addHeading() { return this; },
    addTable(table) { tables.push(table); return this; },
    async write() {},
  };
  return {
    deleted, outputs, tables,
    args: {
      now,
      github: {
        rest: { actions },
        paginate: async (method, options) => {
          assert.equal(method, actions.listArtifactsForRepo);
          assert.deepEqual(options, { owner: 'owner', repo: 'repo', per_page: 100 });
          return artifacts;
        },
      },
      context: { repo: { owner: 'owner', repo: 'repo' }, eventName, payload: { inputs } },
      core: { summary, info() {}, error() {}, setOutput(key, value) { outputs[key] = value; } },
    },
  };
}

test('manual runs preview by default, scheduled runs delete', async () => {
  for (const eventName of ['workflow_dispatch', 'schedule']) {
    const f = fixture([artifact(1, 31)], { eventName });
    const result = await cleanup(f.args);
    assert.equal(result.dryRun, eventName === 'workflow_dispatch');
    assert.deepEqual(f.deleted, eventName === 'schedule' ? [1] : []);
  }
});

test('manual false (string or boolean) deletes; true only previews', async () => {
  for (const dry_run of ['false', false, 'true', true]) {
    const f = fixture([artifact(1, 31)], { inputs: { dry_run } });
    await cleanup(f.args);
    assert.deepEqual(f.deleted, dry_run === false || dry_run === 'false' ? [1] : []);
  }
});

test('preserves metadata for 90 days and images for 30 without explicit expiry', async () => {
  const f = fixture([
    artifact(1, 31), artifact(2, 29),
    artifact(3, 89, 'build-metadata-x86_64-sha'),
    artifact(4, 90, 'build-metadata-aarch64-sha'),
  ], { eventName: 'schedule' });
  await cleanup(f.args);
  assert.deepEqual(f.deleted, [1, 4]);
});

test('honors explicit per-artifact expiry instead of shortening retention', async () => {
  const f = fixture([
    { ...artifact(1, 60), expires_at: ago(-30) },
    { ...artifact(2, 10), expires_at: ago(1) },
  ], { eventName: 'schedule' });
  await cleanup(f.args);
  assert.deepEqual(f.deleted, [2]);
});

test('explicit manual retention overrides expiry and fallback policy', async () => {
  const f = fixture([
    { ...artifact(1, 8, 'build-metadata-sha'), expires_at: ago(-30) }, artifact(2, 6),
  ], { inputs: { dry_run: 'false', retention_days: '7' } });
  await cleanup(f.args);
  assert.deepEqual(f.deleted, [1]);
});

test('validates retention before listing or deleting anything', async () => {
  for (const retention_days of ['0', '-1', '1.5', '3650', 'NaN', '1; process.exit()', ' 30 ']) {
    const f = fixture([artifact(1, 100)], { inputs: { dry_run: false, retention_days } });
    await assert.rejects(cleanup(f.args), /retention_days/);
    assert.deepEqual(f.deleted, []);
  }
});

test('processes all paginated results including artifacts beyond the first 100', async () => {
  const f = fixture(Array.from({ length: 205 }, (_, index) => artifact(index, 31)), { eventName: 'schedule' });
  const result = await cleanup(f.args);
  assert.equal(result.scanned, 205);
  assert.equal(f.deleted.length, 205);
});

test('untrusted artifact names stay data; counts reflect successful deletions and failures propagate', async () => {
  const f = fixture([
    artifact(1, 31, "quote'\n::error::${process.exit()}"), artifact(2, 31), artifact(3, 31),
  ], { eventName: 'schedule', fail: [2] });
  await assert.rejects(cleanup(f.args), /1 artifact deletion\(s\) failed/);
  assert.deepEqual(f.deleted, [1, 3]);
  assert.equal(f.outputs.deleted_count, 2);
  assert.equal(f.outputs.deleted_bytes, 2048);
  assert.ok(f.tables[0].some(row => row[0] === 'Failed deletions' && row[1] === '1'));
});

test('malformed dates fail closed before any deletion', async () => {
  for (const data of [{ created_at: 'invalid' }, { expires_at: 'invalid' }]) {
    const f = fixture([artifact(1, 31), { ...artifact(2, 31), ...data }], { eventName: 'schedule' });
    await assert.rejects(cleanup(f.args), /Invalid .* date/);
    assert.deepEqual(f.deleted, []);
  }
});
