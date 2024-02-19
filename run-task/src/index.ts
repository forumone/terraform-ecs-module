import { Task } from "@aws-sdk/client-ecs";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";

import computeExitInfo, { TaskStatus } from "./computeExitInfo.js";
import ECSClientWrapper from "./ECSClientWrapper.js";
import Output from "./output/index.js";
import SSMClientWrapper from "./SSMClientWrapper.js";
import {
  delay,
  getCommandScript,
  getCredentials,
  getTaskLogsUrl,
} from "./utils.js";

// Define the option types for this command
const parser = yargs(hideBin(process.argv))
  .option("cluster", {
    type: "string",
    describe: "Name of the ECS cluster being communicated with",
    demandOption: true,
  })
  .option("region", {
    type: "string",
    describe: "AWS region to use for making API calls",
    demandOption: true,
  })
  .option("assume-role", {
    type: "string",
    describe:
      "Role ARN to assume (used when connecting Buildkite to another account)",
  })
  .option("task-definition", {
    type: "string",
    describe: "Task definition family to launch in the cluster",
    demandOption: true,
  })
  .option("security-group", {
    type: "array",
    string: true,
    describe: "List of SSM parameters naming security groups to use",
  })
  .option("override-cpu", {
    type: "number",
    describe: "Override CPU to provide more compute power, if needed",
  })
  .option("override-memory", {
    type: "number",
    describe: "Override memory to provide more, if needed",
  })
  .option("container-name", {
    type: "string",
    describe:
      "Sets the container name for command overrides and exit status checking",
  })
  .option("container-command", {
    type: "string",
    describe:
      "Optional command string to run, prefixed with @ if a file should be read",
    implies: "container-name",
  })
  .option("started-by", {
    type: "string",
    describe: "Add a startedBy field to the task being run",
  })
  .strict();

const argv = parser.wrap(parser.terminalWidth()).parseSync();

try {
  // Get our logger instance
  const output = new Output();

  // Resolve the container command (see above)
  argv.containerCommand = await getCommandScript(argv.containerCommand);

  // Determine our credentials provider (default or AssumeRole-based)
  const credentials = getCredentials(argv.region, argv.assumeRole);

  // Create API helpers
  const ssm = new SSMClientWrapper(argv.cluster, argv.region, credentials);
  const ecs = new ECSClientWrapper(argv.cluster, argv.region, credentials, ssm);

  // Begin: spawn the ECS task and output its full ARN
  output.print(output.heading("ecs", "Spawning task"));
  const taskArn = await ecs.runTask(argv);
  output.print(`--> ${taskArn}`);

  // Print a link to the task logs in the ECS console. Note that this isn't the
  // long-lived CloudWatch log stream link, which means that it'll expire
  // sometime after ECS cleans up the task.
  output.print(
    output.link(
      getTaskLogsUrl(argv.cluster, argv.region, taskArn),
      `Task logs: ${taskArn.split("/").pop()}`
    )
  );

  // Print a blank line before continuing
  output.print("");

  // From here, we begin a wait loop waiting for ECS to finish. Note that there
  // is a wait function available for a task to stop, but we don't use it as
  // some of our deployment tasks take longer than that and we can't really
  // restart a waiter due to how Buildkite works.
  output.print(output.heading("ecs", "Watching task status"));

  // Final task object from the API
  let task: Task;

  // Last-seen status of the task
  let lastStatus: string | undefined;
  while (true) {
    await delay();

    const status = await ecs.checkStatus(taskArn);

    // If the ECS helper returned an object to us, that means the task stopped.
    if (typeof status === "object") {
      task = status;
      break;
    }

    // This case happens when tasks have just finished booting; we don't really
    // care about it and just don't display it to avoid printing "Status:
    // undefined" to the console.
    if (status === undefined) {
      continue;
    }

    // If the status changed since the last time we recorded it, print it. This
    // follows the ECS task lifecycle (pending -> provisioning -> running ->
    // stopping -> stopped).
    if (lastStatus !== status) {
      output.print(`Status: ${lastStatus}`);
      lastStatus = status;
    }
  }

  // Translate the API statuses into somewhat more human-readable output, and
  // then print them below
  const info = computeExitInfo(task, argv.containerName);

  output.print(`Task stop: ${info.stop}`);
  output.print(`Container exit: ${info.exit}`);
  if (info.signal) {
    // This is really important to track if it ever happens; crashes due to
    // signals are very bad news.
    output.print(`  NOTE: Container exited due to signal ${info.signal}`);
  }

  switch (info.status) {
    case TaskStatus.Unknown:
      output.print(
        "WARNING: Success or failure of the container could not be determined"
      );
      break;

    case TaskStatus.Failure:
      output.print(
        output.link(
          getTaskLogsUrl(argv.cluster, argv.region, taskArn),
          `Review task logs: ${taskArn.split("/").pop()}`
        )
      );
      throw new Error(`Task did not exit cleanly`);
  }
} catch (error) {
  console.error(error);
  process.exitCode = 1;
}
