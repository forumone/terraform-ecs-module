import {
  GetParameterCommand,
  GetParametersCommand,
  SSMClient,
} from "@aws-sdk/client-ssm";
import { AwsCredentialIdentityProvider } from "@aws-sdk/types";

/**
 * Helper class for interaction with Systems Manager (specifically, Parameter
 * Store)
 */
class SSMClientWrapper {
  #cluster: string;
  #ssm: SSMClient;

  constructor(
    cluster: string,
    region: string,
    credentials: AwsCredentialIdentityProvider | undefined
  ) {
    this.#cluster = cluster;
    this.#ssm = new SSMClient({ region, credentials });
  }

  /**
   * Load the list of the cluster's private subnet IDs from Parameter Store.
   */
  async getSubnets(): Promise<string[]> {
    const name = `/${this.#cluster}/vpc/private-subnets`;

    const response = await this.#ssm.send(
      new GetParameterCommand({ Name: name })
    );

    const value = response.Parameter?.Value;
    if (value === undefined) {
      throw new Error(`Failed to read parameter ${name}: undefined value`);
    }

    return value.split(",");
  }

  /**
   * Loads security groups given an optional list of Parameter Store names.
   */
  async getSecurityGroups(names: string[] = []) {
    const defaultGroup = `/${this.#cluster}/security-groups/default`;

    const response = await this.#ssm.send(
      new GetParametersCommand({
        Names: [defaultGroup, ...names],
      })
    );

    // If the API complained about any invalid parameters, throw an error listing them all
    const invalid = response.InvalidParameters ?? [];
    if (invalid.length > 0) {
      throw new Error(`Invalid SSM parameters: ${invalid.join(", ")}`);
    }

    // Assemble the array of parameter values (we don't care about the name),
    // but throw errors if a value wasn't set
    const parameters = response.Parameters ?? [];
    return parameters.map((parameter) => {
      const value = parameter.Value;
      if (value === undefined) {
        throw new Error(
          `Failed to read parameter ${parameter.Name}: undefined value`
        );
      }

      return value;
    });
  }
}

export default SSMClientWrapper;
