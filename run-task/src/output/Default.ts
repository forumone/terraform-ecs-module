import { Output } from "./types.js";

/**
 * Default implementation of the
 */
class Default implements Output {
  // Prints a Markdown-inspired link
  link(url: string, content?: string): string {
    return content ? `[${content}]: ${url}` : url;
  }

  // Prints a "*"-noted header
  heading(_emoji: string, message: string): string {
    return `* ${message}`;
  }

  print(message: string): void {
    process.stdout.write(message + "\n");
  }
}

export default Default;
