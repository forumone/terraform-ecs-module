import { Output } from "./types.js";

/**
 * Buildkite-specific implementation of the CI `Output` functionality.
 */
class Buildkite implements Output {
  link(url: string, content?: string): string {
    let link = `url='${url}'`;
    if (content) {
      link += `;content='${content}'`;
    }

    return `\x1b]1339;${link}\x07`;
  }

  heading(emoji: string, message: string): string {
    return `--- :${emoji}: ${message}`;
  }

  print(message: string): void {
    process.stdout.write(message + "\n");
  }
}

export default Buildkite;
