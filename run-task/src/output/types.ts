/**
 * Base interfae type for console output helpers. Implementations customize the
 * output in order to add the intended functionality, such as hyperlinks or
 * collapsible headings.
 */
export interface Output {
  /**
   * Returns a formatted string intended for use as a hyperlink.
   *
   * @param url The URL to link to
   * @param content An optional string to present instead of the link
   */
  link(url: string, content?: string): string;

  /**
   * Returns a formatted string for use as a heading in CI output.
   *
   * @param emoji An emoji, for platforms that support it
   * @param message The heading to print
   */
  heading(emoji: string, message: string): string;

  /**
   * Prints a line of text to the CI console, followed by a newline.
   *
   * @param message The message to print
   */
  print(message: string): void;
}

/**
 * Type to identify classes that can be instantiated to an {@link Output}
 * object.
 */
export type OutputConstructor = new () => Output;
