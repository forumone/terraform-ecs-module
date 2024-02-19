import { constants } from "node:os";

import { Container, Task, TaskStopCode } from "@aws-sdk/client-ecs";

export enum TaskStatus {
  Unknown = "Unknown",
  Success = "Success",
  Failure = "Failure",
}

export interface ExitInfo {
  /**
   * The stop code and/or stop reason indicating why this task stopped.
   */
  stop: string;

  /**
   * The exit code and/or reason indicating why a named container exited.
   */
  exit: string;

  /**
   * If a named container exited by a signal, the number and/or name of that
   * signal.
   */
  signal?: string;

  /**
   * Overall success status of the task. TaskStatus.Unknown means we couldn't
   * figure it out (either the API didn't tell us, or we didn't watch a specific
   * container).
   */
  status: TaskStatus;
}

/**
 * Helper function to combine code/reason information from the AWS API into a
 * human-readable string. `code` may be numeric for process exit codes or signals.
 */
function combineCodeAndReason(
  code: string | number | undefined,
  reason: string | undefined
): string {
  if (code !== undefined && reason !== undefined) {
    return `${code} (${reason})`;
  }

  if (code !== undefined) {
    return String(code);
  }

  if (reason !== undefined) {
    return reason;
  }

  return "Unavailable";
}

/**
 * Tries to find the signal name given a process exit code. If the code doesn't
 * correspond to a signal exit, returns `undefined`.
 */
function getSignal(code: number): string | undefined {
  if (code < 128) {
    return;
  }

  const signalNumber = code - 128;
  const signalName = Object.entries(constants.signals).find(
    (info) => info[1] === signalNumber
  )?.[0];

  return combineCodeAndReason(signalNumber, signalName);
}

/**
 * Finds a container by name. In simple (i.e., one-container) cases, just returns the container
 */
function findContainer(
  containers: readonly Container[],
  name: string | undefined
) {
  if (name !== undefined) {
    return containers.find((container) => container.name === name);
  }

  if (containers.length === 1) {
    return containers[0];
  }
}

/**
 * Computes stop and exit information from the AWS API. Stop information is
 * related to why the task moved to the "STOPPED" state in AWS, such as
 * essential containers exiting or tasks failing to launch. Exit information is
 * related to why a tracked container exited; this will be the typical UNIX
 * convention of exit code or signal.
 *
 * Because we are not running long-lived tasks, we expected a stop of
 * EssentialContainerExited along with an exit code of 0.
 *
 * @param task The task returned from the AWS API.
 * @param containerName The name of a container to track exit codes from.
 * @returns A simplified `ExitInfo` object indicating task status.
 */
function computeExitInfo(
  task: Task,
  containerName: string | undefined
): ExitInfo {
  // stop code and/or reason
  const stop = combineCodeAndReason(task.stopCode, task.stoppedReason);

  // Container exit code
  let exitCode: number | undefined;

  // exit code and/or reason
  let exit: string | undefined;

  // signal (if any)
  let signal: string | undefined;

  // success (if we could figure it out)
  let status = TaskStatus.Unknown;

  const container = findContainer(task.containers ?? [], containerName);
  if (container) {
    exitCode = container.exitCode;

    exit = combineCodeAndReason(exitCode, container.reason);

    if (exitCode !== undefined) {
      signal = getSignal(exitCode);

      const success =
        task.stopCode === TaskStopCode.ESSENTIAL_CONTAINER_EXITED &&
        exitCode === 0;

      status = success ? TaskStatus.Success : TaskStatus.Failure;
    }
  }

  return {
    exit: exit ?? "Unknown",
    stop,
    signal,
    status,
  };
}

export default computeExitInfo;
