import {
  AssignPublicIp,
  DescribeTasksCommand,
  DesiredStatus,
  ECSClient,
  Failure,
  RunTaskCommand,
  RunTaskCommandInput,
  Task,
  TaskOverride,
} from "@aws-sdk/client-ecs";
import { AwsCredentialIdentityProvider } from "@aws-sdk/types";

import SSMClientWrapper from "./SSMClientWrapper.js";

/** Transform ECS `Failure` objects into error strings that we can print to the user */
function aggregateFailures(failures: readonly Failure[]): string {
  return failures
    .map(
      ({ arn = "", detail = "", reason = "" }) =>
        `arn=${arn}; detail=${detail}; reason=${reason}`
    )
    .join("\n");
}

/**
 * Type for all of the options for ECSClientWrapper's `runTask` method. This
 * should be compatible with the command's overall options in order to avoid
 * rote type transformation.
 */
interface RunTaskOptions {
  taskDefinition: string;
  overrideCpu?: number;
  overrideMemory?: number;
  containerName?: string;
  containerCommand?: string;
  startedBy?: string;
  securityGroups?: string[];
}

class ECSClientWrapper {
  #cluster: string;
  #ecs: ECSClient;
  #ssm: SSMClientWrapper;

  constructor(
    cluster: string,
    region: string,
    credentials: AwsCredentialIdentityProvider | undefined,
    ssm: SSMClientWrapper
  ) {
    this.#cluster = cluster;

    this.#ecs = new ECSClient({ region, credentials });
    this.#ssm = ssm;
  }

  /**
   * Spawn a task in ECS. If all goes well, the returned value is a task ARN
   * that can be used to look up its status later.
   */
  async runTask(options: RunTaskOptions): Promise<string> {
    const {
      taskDefinition,
      overrideCpu,
      overrideMemory,
      containerName,
      containerCommand,
      startedBy,
      securityGroups,
    } = options;

    // Store task overrides
    const overrides: TaskOverride = {};

    if (overrideCpu !== undefined) {
      overrides.cpu = String(overrideCpu);
    }

    if (overrideMemory !== undefined) {
      overrides.memory = String(overrideMemory);
    }

    // Only override the container command if both arguments were set (yargs
    // checks this for us, but it's not something TypeScript can model).
    if (containerName !== undefined && containerCommand !== undefined) {
      overrides.containerOverrides = [
        {
          name: containerName,
          command: [containerCommand],
        },
      ];
    }

    const input: RunTaskCommandInput = {
      cluster: this.#cluster,
      taskDefinition,

      overrides,

      startedBy,

      networkConfiguration: {
        awsvpcConfiguration: {
          subnets: await this.#ssm.getSubnets(),
          securityGroups: await this.#ssm.getSecurityGroups(securityGroups),
          assignPublicIp: AssignPublicIp.DISABLED,
        },
      },
    };

    const response = await this.#ecs.send(new RunTaskCommand(input));

    // If the AWS API sent failures back, bail
    const failures = response.failures ?? [];
    if (failures.length > 0) {
      throw new Error(aggregateFailures(failures));
    }

    // If we couldn't get tasks back, bail
    const task = response.tasks?.[0];
    if (task === undefined) {
      throw new Error(
        `Failed to start ${
          this.#cluster
        }/${taskDefinition}: no task in API response`
      );
    }

    // And, finally, if we couldn't get an ARN, we bail
    const taskArn = task.taskArn;
    if (taskArn === undefined) {
      throw new Error(
        `Failed to start ${
          this.#cluster
        }/${taskDefinition}: no task ARN in API response`
      );
    }

    // At this point it's safe to assume we actually have a task ARN so we
    // return it
    return taskArn;
  }

  /**
   * Determine the status of a given task ARN. There are three possible return
   * values:
   *
   * 1. If ECS hasn't yet fully registered the task, its status is `undefined`.
   * 2. If the task is running but not yet fully stopped, this function returns
   *    a string.
   * 3. If the task has stopped, the full task is returned so that it can be
   *    inspected.
   */
  async checkStatus(taskArn: string): Promise<string | undefined | Task> {
    const response = await this.#ecs.send(
      new DescribeTasksCommand({
        cluster: this.#cluster,
        tasks: [taskArn],
      })
    );

    // Did the ECS API report any failures? If so, bail
    const failures = response.failures ?? [];
    if (failures.length > 0) {
      throw new Error(aggregateFailures(failures));
    }

    // Did we actually get a task back? If not, bail
    const task = response.tasks?.[0];
    if (task === undefined) {
      throw new Error(
        `Could not check status of ${taskArn}: no task in API response`
      );
    }

    // If the task is still running, return its status
    const status = task.lastStatus;
    if (status !== DesiredStatus.STOPPED) {
      return status;
    }

    // At this point the task is stopped so we can report its status
    return task;
  }
}

export default ECSClientWrapper;
