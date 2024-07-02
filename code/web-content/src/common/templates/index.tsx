/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */
import { ReactNode } from "react";
import { ApiErrorHandler, ApiResponseWrapper } from "../error";
import { InstanceInterface } from "../instance";
import axios from "axios";
import { getCurrentSessionJwtToken, handleError } from "../cognito";
import { getCurrentUserName } from "../../common/cognito";

export interface TemplateInterface {
  id: string;
  name: string;
  description: string;
  createdAt: string;
  createdBy: string;

  defaultVersion: number;
  latestVersion: number;

  osFamily: string;
  osPlatform: string;
  osVersion: string;

  components: string;
  policies: string;

  instanceFamilies: string[];
  instanceSizes: string[];

  volumeType: string;
  volumeSize: number;
  volumeSizeMin: number;
  volumeSizeMax: number;
  volumeIops: number;
  volumeIopsMin: number;
  volumeIopsMax: number;
  volumeThroughput: number;
  volumeThroughputMin: number;
  volumeThroughputMax: number;
}

export interface TemplateLaunchParametersValidationInterface {
  volumeSizeMin: number;
  volumeSizeMax: number;

  volumeIopsMin: number;
  volumeIopsMax: number;

  volumeThroughputMin: number;
  volumeThroughputMax: number;

  instanceNameMin?: number;
  instanceNameMax?: number;
  instanceNamePattern?: string;

  instanceDescriptionMin?: number;
  instanceDescriptionMax?: number;
  instanceDescriptionPattern?: string;
}

export interface TemplateLaunchParametersInterface {
  templateName: string;

  instanceName: string;
  instanceDescription: string;

  launchTemplateId: string;
  launchTemplateVersion: number;

  instanceType: string;

  volumeType: string;
  volumeSize: number;
  volumeIops: number;
  volumeThroughput: number;
}

export async function listTemplates(): Promise<ApiResponseWrapper<{ items: TemplateInterface[] }, ApiErrorHandler>> {
  try {
    const restOperation = axios.get("api/portal/templates/list", {
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${await getCurrentSessionJwtToken()}` },
    });
    const response = (await restOperation).data;
    return [{ items: response['templates'] }, undefined];
  } catch (error) {
    // Print out the actual error given back to us.
    console.error(error);
    await handleError(error);
    return [undefined, error];
  }
}

export async function launchTemplate(
  templateLaunchParameters: TemplateLaunchParametersInterface,
): Promise<ApiResponseWrapper<InstanceInterface, ApiErrorHandler>> {
  try {

    const username = await getCurrentUserName();
    const restOperation = axios.post(`api/portal/templates/launch`,
      {
        items: [
          {
            count: 1,
            ...templateLaunchParameters,
          },
        ],
      },
      {
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${await getCurrentSessionJwtToken()}` },
      }
    );
    const response = (await restOperation).data;
    return [response[0]['instances'][0], undefined];
  } catch (error) {
    // Print out the actual error given back to us.
    console.error(error);
    await handleError(error);
    return [undefined, error];
  }
}
