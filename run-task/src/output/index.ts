import Buildkite from "./Buildkite.js";
import Default from "./Default.js";
import { OutputConstructor } from "./types.js";

// Pick the implementation based on whether or not the $BUILDKITE environment variable is set
const isBuildkite = process.env.BUILDKITE === "true";

const Output: OutputConstructor = isBuildkite ? Buildkite : Default;
export default Output;
