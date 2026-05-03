const fs = require('fs');
const core = require('@actions/core');
const github = require('@actions/github');

async function run() {
  try {
    const planPath = core.getInput('plan-file');
    const token = process.env.GITHUB_TOKEN;
    
    if (!fs.existsSync(planPath)) {
      core.setFailed(`The plan file was not found at path: ${planPath}`);
      return;
    }

    const plan = fs.readFileSync(planPath, 'utf8');
    const octokit = github.getOctokit(token);
    const context = github.context;

    if (context.payload.pull_request == null) {
      core.notice("This is not a Pull Request. The comment will not be posted.");
      return;
    }

    const maxLen = 60000;
    const trimmedPlan = plan.length > maxLen ? plan.substring(0, maxLen) + '\n... (plan truncated due to size)' : plan;

    const body = `
        #### Terraform Plan Output for \`${context.payload.pull_request.head.ref}\`
        <details><summary>Click here to see the plan details</summary>

        \`\`\`hcl
        ${trimmedPlan}
        \`\`\`

        </details>

        *Pusher: @${context.actor}, Action: \`${context.eventName}\`*
    `.replace(/^ +/gm, '').trim(); 

    await octokit.rest.issues.createComment({
      ...context.repo,
      issue_number: context.payload.pull_request.number,
      body: body
    });

    core.info("The plan has been successfully posted on the Pull Request!");

  } catch (error) {
    core.setFailed(`Error posting the comment: ${error.message}`);
  }
}

run();
