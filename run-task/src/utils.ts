import fs from "node:fs/promises";
import posix from "node:path/posix";

import { fromTemporaryCredentials } from "@aws-sdk/credential-providers";
import { AwsCredentialIdentityProvider } from "@aws-sdk/types";

/**
 * Optionally create a credential provider based on the `assumeRole` argument.
 * If present, this will chain an STS AssumeRole provider to the default
 * provider. If absent, this will return `undefined` which forces the SDK to use
 * the default provider chain.
 */
export function getCredentials(
  region: string,
  assumeRole?: string
): AwsCredentialIdentityProvider | undefined {
  if (assumeRole) {
    return fromTemporaryCredentials({
      clientConfig: {
        region
      },
      params: {
        RoleArn: assumeRole,
      },
    });
  }
}

/**
 * Helper function to resolve a container command passed to the `run-task`
 * subcommand. If the command begins with an `@` sign, we read a script file
 * from the filesystem.
 */
export async function getCommandScript(
  command: string | undefined
): Promise<string | undefined> {
  if (command === undefined) {
    return command;
  }

  if (!command.startsWith("@")) {
    return command;
  }

  return fs.readFile(command.slice(1), "utf-8");
}

/**
 * Helper function to convert the callback-based `setTimeout` into an async
 * `Promise` we can await. This function waits for a random number of seconds
 * before resolving.
 */
export async function delay(): Promise<void> {
  // Wait for between 5 and 10 seconds: we do this to avoid stampeding the AWS
  // API and to give it more time to have actual updates
  const duration = 5_000 + Math.floor(Math.random() * 5_000);

  return new Promise((resolve) => {
    setTimeout(() => resolve(), duration);
  });
}

/**
 * Gets the link to a task's logs based on its ARN, the name of the cluster, and
 * the current AWS region.
 */
export function getTaskLogsUrl(
  cluster: string,
  region: string,
  taskArn: string
): string {
  // NB. Trailing '!' because calling pop() can't fail due to the structure of
  // an ECS task ARN.
  const taskId = taskArn.split("/").pop()!;

  const url = new URL(`https://${region}.console.aws.amazon.com`);

  // Add the region query string parameter just like the AWS Console does
  url.searchParams.set("region", region);

  url.pathname = posix.join(
    "ecs/v2/clusters",
    cluster,
    "tasks",
    taskId,
    "logs"
  );

  return String(url);
}
