'use strict';

const DAY_MS = 24 * 60 * 60 * 1000;

module.exports = async function cleanupArtifacts({ github, context, core, now = Date.now() }) {
  const inputs = context.eventName === 'workflow_dispatch' ? context.payload.inputs || {} : {};
  const dryRun = context.eventName !== 'schedule' && inputs.dry_run !== 'false' && inputs.dry_run !== false;
  const retention = inputs.retention_days;
  let override;
  if (retention !== undefined && retention !== '') {
    if (!/^[1-9][0-9]*$/.test(String(retention)) || Number(retention) > 365) {
      throw new Error('retention_days must be an integer from 1 to 365, or empty');
    }
    override = Number(retention);
  }

  const { owner, repo } = context.repo;
  // Snapshot every page before deleting: deletion while paging can skip entries.
  const artifacts = await github.paginate(github.rest.actions.listArtifactsForRepo, {
    owner, repo, per_page: 100,
  });
  const candidates = artifacts.filter(artifact => {
    const created = Date.parse(artifact.created_at);
    if (!Number.isFinite(created)) throw new Error(`Invalid creation date for artifact ${artifact.id}`);
    let deadline;
    if (override !== undefined) {
      deadline = created + override * DAY_MS;
    } else if (artifact.expires_at) {
      deadline = Date.parse(artifact.expires_at);
      if (!Number.isFinite(deadline)) throw new Error(`Invalid expiry date for artifact ${artifact.id}`);
    } else {
      deadline = created + (artifact.name.startsWith('build-metadata-') ? 90 : 30) * DAY_MS;
    }
    return deadline <= now;
  });

  let deleted = 0;
  let deletedBytes = 0;
  const failures = [];
  for (const artifact of candidates) {
    if (dryRun) {
      core.info(`Preview: ${artifact.id} ${JSON.stringify(artifact.name)}`);
      continue;
    }
    try {
      await github.rest.actions.deleteArtifact({ owner, repo, artifact_id: artifact.id });
      deleted++;
      deletedBytes += artifact.size_in_bytes;
      core.info(`Deleted: ${artifact.id} ${JSON.stringify(artifact.name)}`);
    } catch (error) {
      failures.push(error);
      core.error(`Failed to delete artifact ${artifact.id}: ${error.message}`);
    }
  }

  core.setOutput('deleted_count', deleted);
  core.setOutput('deleted_bytes', deletedBytes);
  await core.summary.addHeading('Artifact cleanup').addTable([
    [{ data: 'Metric', header: true }, { data: 'Value', header: true }],
    ['Mode', dryRun ? 'Preview (no deletions)' : 'Delete'],
    ['Retention', override === undefined ? 'Per-artifact expiry; fallback: metadata 90 days, others 30 days' : `${override} days (explicit override)`],
    ['Scanned', String(artifacts.length)],
    ['Eligible', String(candidates.length)],
    ['Deleted', String(deleted)],
    ['Deleted bytes', String(deletedBytes)],
    ['Failed deletions', String(failures.length)],
  ]).write();
  if (failures.length) throw new AggregateError(failures, `${failures.length} artifact deletion(s) failed`);
  return { scanned: artifacts.length, eligible: candidates.length, deleted, deletedBytes, dryRun };
};
