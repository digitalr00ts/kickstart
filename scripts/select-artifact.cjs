'use strict';

module.exports = async function selectArtifact({ github, context, core, env = process.env }) {
  const { owner, repo } = context.repo;
  const requestedRun = (env.REQUESTED_RUN || '').trim();
  const requestedName = env.REQUESTED_ARTIFACT || '';
  if (!['x86_64', 'aarch64'].includes(env.IMAGE_ARCH)) {
    throw new Error('IMAGE_ARCH must be x86_64 or aarch64');
  }
  const pattern = new RegExp(`^fedora-[0-9]+-${env.IMAGE_ARCH}-[0-9a-f]{8}$`);
  if (requestedRun && !/^[1-9][0-9]*$/.test(requestedRun)) {
    throw new Error('run_id must be a positive integer');
  }
  async function select(run) {
    if (run.conclusion !== 'success' || run.status !== 'completed' ||
        run.head_repository?.full_name !== `${owner}/${repo}` ||
        run.path !== '.github/workflows/build.yml') {
      if (requestedRun) throw new Error('Run must be a successful same-repository Build run');
      return false;
    }
    const artifacts = await github.paginate(github.rest.actions.listWorkflowRunArtifacts, {
      owner, repo, run_id: run.id, per_page: 100,
    });
    const matches = artifacts.filter(a => !a.expired && pattern.test(a.name) &&
      (!requestedName || a.name === requestedName));
    if (matches.length > 1) throw new Error(`Ambiguous image artifacts in run ${run.id}`);
    if (!matches.length) return false;
    core.setOutput('run_id', String(run.id));
    core.setOutput('name', matches[0].name);
    core.info(`Selected ${matches[0].name} from run ${run.id}`);
    return true;
  }
  if (requestedRun) {
    const { data: run } = await github.rest.actions.getWorkflowRun({
      owner, repo, run_id: requestedRun,
    });
    if (await select(run)) return;
  } else {
    for await (const page of github.paginate.iterator(github.rest.actions.listWorkflowRuns, {
      owner, repo, workflow_id: 'build.yml', status: 'success', per_page: 100,
    })) {
      // Octokit normalizes workflow_runs into the page.data array.
      for (const run of page.data) {
        if (await select(run)) return;
      }
    }
  }
  throw new Error('No unexpired image artifact matches the requested run/name/architecture');
};
