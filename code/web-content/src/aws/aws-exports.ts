/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */
import { ResourcesConfig } from 'aws-amplify';
import * as config from "../../export/aws-config";

const authConfig: ResourcesConfig['Auth'] = {
  Cognito: config.cognito
};

export default {
  config: {
    Auth: authConfig
  },
  options: {
  },
  app_config: config
}
