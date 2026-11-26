'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const selectArtifact = require('../scripts/select-artifact.cjs');

const image = (sha = '12345678', arch = 'x86_64') => ({
  name: `fedora-44-${arch}-${sha}`, expired: false,
});
const run = id => ({
  id, conclusion: 'success', status: 'completed',
  head_repository: { full_name: 'owner/repo' }, path: '.github/workflows/build.yml',
});

function fixture({ pages = [[run(2)], [run(1)]], artifacts = {}, env = {}, explicitRun = run(1) } = {}) {
  const outputs = {};
  const visitedPages = [];
  const artifactRuns = [];
  const actions = {
    listWorkflowRuns() { throw new Error('Must use paginated iterator'); },
    listWorkflowRunArtifacts() { throw new Error('Must paginate artifacts'); },
    async getWorkflowRun(options) {
      assert.deepEqual(options, { owner: 'owner', repo: 'repo', run_id: env.REQUESTED_RUN.trim() });
      return { data: explicitRun };
    },
  };
  const paginate = async (method, options) => {
    assert.equal(method, actions.listWorkflowRunArtifacts);
    assert.deepEqual(options, { owner: 'owner', repo: 'repo', run_id: options.run_id, per_page: 100 });
    artifactRuns.push(options.run_id);
    return artifacts[options.run_id] || [];
  };
  paginate.iterator = async function* (method, options) {
    assert.equal(method, actions.listWorkflowRuns);
    assert.deepEqual(options, {
      owner: 'owner', repo: 'repo', workflow_id: 'build.yml', status: 'success', per_page: 100,
    });
    for (const [index, data] of pages.entries()) {
      visitedPages.push(index);
      // Match Octokit's normalized response, not GitHub's raw workflow_runs object.
      yield { data, status: 200, headers: {}, url: 'https://api.github.com/repos/owner/repo/actions/runs' };
    }
  };
  return {
    outputs, visitedPages, artifactRuns,
    args: {
      github: { rest: { actions }, paginate },
      context: { repo: { owner: 'owner', repo: 'repo' } },
      core: { info() {}, setOutput(key, value) { outputs[key] = value; } },
      env: { IMAGE_ARCH: 'x86_64', ...env },
    },
  };
}

test('default selection iterates normalized page.data arrays across pages', async () => {
  const f = fixture({ artifacts: { 2: [image('aaaaaaaa', 'aarch64')], 1: [image()] } });
  await selectArtifact(f.args);
  assert.deepEqual(f.visitedPages, [0, 1]);
  assert.deepEqual(f.artifactRuns, [2, 1]);
  assert.deepEqual(f.outputs, { run_id: '1', name: image().name });
});

test('selects latest matching successful run and stops pagination', async () => {
  const f = fixture({ artifacts: { 2: [image()], 1: [image('aaaaaaaa')] } });
  await selectArtifact(f.args);
  assert.deepEqual(f.visitedPages, [0]);
  assert.equal(f.outputs.run_id, '2');
});

test('explicit run and exact artifact name are honored without listing runs', async () => {
  const selected = image('aaaaaaaa', 'aarch64');
  const f = fixture({
    env: { REQUESTED_RUN: ' 1 ', REQUESTED_ARTIFACT: selected.name, IMAGE_ARCH: 'aarch64' },
    artifacts: { 1: [image(), image('bbbbbbbb', 'aarch64'), selected] },
  });
  await selectArtifact(f.args);
  assert.deepEqual(f.visitedPages, []);
  assert.deepEqual(f.outputs, { run_id: '1', name: selected.name });
});

test('rejects ambiguous artifacts rather than choosing the first', async () => {
  const f = fixture({ artifacts: { 2: [image(), image('aaaaaaaa')] } });
  await assert.rejects(selectArtifact(f.args), /Ambiguous/);
  assert.deepEqual(f.outputs, {});
});

test('expired, metadata and wrong-architecture artifacts never match', async () => {
  const f = fixture({ artifacts: { 2: [
    { ...image(), expired: true }, image('aaaaaaaa', 'aarch64'),
    { name: 'build-metadata-x86_64-sha', expired: false },
  ] } });
  await assert.rejects(selectArtifact(f.args), /No unexpired image artifact/);
});

test('skips unsuccessful, foreign-repository and non-build runs', async () => {
  const f = fixture({
    pages: [[
      { ...run(5), conclusion: 'failure' }, { ...run(4), status: 'in_progress' },
      { ...run(3), head_repository: { full_name: 'fork/repo' } },
      { ...run(2), path: '.github/workflows/other.yml' }, run(1),
    ]],
    artifacts: { 1: [image()] },
  });
  await selectArtifact(f.args);
  assert.deepEqual(f.artifactRuns, [1]);
});

test('explicit invalid run fails without falling back to another run', async () => {
  for (const change of [
    { conclusion: 'failure' }, { status: 'in_progress' },
    { head_repository: null }, { path: '.github/workflows/other.yml' },
  ]) {
    const f = fixture({ env: { REQUESTED_RUN: '1' }, explicitRun: { ...run(1), ...change } });
    await assert.rejects(selectArtifact(f.args), /successful same-repository Build run/);
    assert.deepEqual(f.visitedPages, []);
    assert.deepEqual(f.artifactRuns, []);
  }
});

test('explicit unmatched artifact fails without falling back', async () => {
  const f = fixture({
    env: { REQUESTED_RUN: '1', REQUESTED_ARTIFACT: image('aaaaaaaa').name },
    artifacts: { 1: [image()] },
  });
  await assert.rejects(selectArtifact(f.args), /No unexpired image artifact/);
  assert.deepEqual(f.visitedPages, []);
});

test('validates run ID and architecture before API calls', async () => {
  for (const env of [{ REQUESTED_RUN: '1.5' }, { REQUESTED_RUN: '-1' }, { IMAGE_ARCH: '.*' }]) {
    const f = fixture({ env });
    await assert.rejects(selectArtifact(f.args), /run_id|IMAGE_ARCH/);
    assert.deepEqual(f.visitedPages, []);
    assert.deepEqual(f.artifactRuns, []);
  }
});
