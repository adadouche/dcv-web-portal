/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */
import { StatusIndicatorProps } from "@cloudscape-design/components/status-indicator";
import { ReactNode, SetStateAction } from "react";
import { ApiErrorHandler, ApiResponseWrapper } from "../error";
import axios from "axios";
import { getCurrentSessionJwtToken, handleError } from "../cognito";
import aws_config from '../../aws/aws-exports.js';
import { getCurrentUserName } from "../../common/cognito";

export interface InstanceInterface {
    instanceId: string;
    name: string;
    description: string;

    instanceState: ReactNode;
    instanceStatusCheck: ReactNode;

    username: string;
    createdAt: string;
    createdBy: string;
    startedAt: string;
    
    launchTemplateId: string;
    launchTemplateName: string;
    launchTemplateVersion: number;

    instanceFamily: string;
    instanceSize: string;
    instanceType: string;
    
    osFamily: string;
    osPlatform: string;

    dcvStatus: string;
    dcvStatusConfigure: string;
    dcvStatusCredentials: string;

    hibernationEnabled: boolean;
};

export enum InstanceActionEnum {
    START = "start",
    STOP = "stop",
    REBOOT = "reboot",
    TERMINATE = "terminate",
    HIBERNATE = "hibernate",
    CONFIGURE = "configure"
}

export enum DCVActionEnum {
    CONFIGURE = "configure",
    RESTART = "restart",
    CREDENTIALS = "create-credentials",
}

export function isNotRunningInstance(selectedItems: ReadonlyArray<InstanceInterface>): boolean {
    if (selectedItems.length !== 1) {
        return false;
    }
    const selectedItem = selectedItems[0];
    if (selectedItem.instanceState === 'stopped') {
        return true;
    }
    return false;
}

export function isRunningInstance(selectedItems: ReadonlyArray<InstanceInterface>): boolean {
    if (selectedItems.length !== 1) {
        return false;
    }
    const selectedItem = selectedItems[0];
    if (selectedItem.instanceState === 'running') {
        return true;
    }
    return false;
}

export function isNotTerminatedInstance(selectedItems: ReadonlyArray<InstanceInterface>): boolean {
    if (selectedItems.length !== 1) {
        return false;
    }
    const selectedItem = selectedItems[0];
    if (selectedItem.instanceState === 'terminated') {
        return false;
    }
    if (selectedItem.instanceState === 'running' || selectedItem.instanceState === 'stopped') {
        return true;
    }
    return false;
}

export function canConfigureDCVSession(selectedItems: ReadonlyArray<InstanceInterface>): boolean {
    if (selectedItems.length !== 1) {
        return false;
    }
    const selectedItem = selectedItems[0];
    if (selectedItem.instanceState !== 'running') {
        return false;
    }
    if (selectedItem.instanceStatusCheck !== 'ok') {
        return false;
    }
    return true;
}

export function canStartDCVSession(selectedItems: ReadonlyArray<InstanceInterface>): boolean {
    if (selectedItems.length !== 1) {
        return false;
    }
    const selectedItem = selectedItems[0];
    if (selectedItem.instanceState !== 'running') {
        return false;
    }
    if (selectedItem.instanceStatusCheck !== 'ok') {
        return false;
    }
    if (selectedItem.dcvStatus !== 'ok') {
        return false;
    }
    return true;
}

export function getInstanceStateIndicator(instanceState: string): StatusIndicatorProps.Type {
    if (instanceState === "running") {
        return "success"
    } else if (instanceState === "stopped") {
        return "stopped"
    } else if (instanceState === "terminated") {
        return "stopped"
    } else if (instanceState === "pending") {
        return "pending"
    } else if (instanceState === "stopping") {
        return "pending"
    } else if (instanceState === "shutting-down") {
        return "pending"
    }
    return "error"
}

export function getInstanceStatusCheckIndicator(instanceStatusCheck: string): StatusIndicatorProps.Type {
    if (instanceStatusCheck === "ok") {
        return "success"
    } else if (instanceStatusCheck === "initializing") {
        return "pending"
    } else if (instanceStatusCheck === "terminated") {
        return "stopped"
    } else if (instanceStatusCheck === "pending") {
        return "pending"
    } else if (instanceStatusCheck === "stopping") {
        return "pending"
    } else if (instanceStatusCheck === "shutting-down") {
        return "pending"
    }
    return "stopped"
}

export function getDCVStatusIndicator(status: string): StatusIndicatorProps.Type {
    if (status === "running") {
        return "success"
    } else if (status === "started") {
        return "success"
    } else if (status === "ok") {
        return "success"
    } else if (status === "pending") {
        return "pending"
    } else if (status === "starting") {
        return "pending"
    } else if (status === "initializing") {
        return "pending"
    } else if (status === "stopped") {
        return "stopped"
    } else if (status === "stopping") {
        return "pending"
    } else if (status === "terminated") {
        return "stopped"
    }
    return "stopped"
}

export async function performInstanceAction(action: string, selectedItems: ReadonlyArray<InstanceInterface>, setLoadingState: { (value: SetStateAction<boolean>): void; (arg0: boolean): void; }, callback: { (): Promise<void>; (): void; }): Promise<void> {
    if (selectedItems.length !== 1) {
        return;
    }
    const instanceId = selectedItems[0].instanceId.toString();
    setLoadingState(true);
    switch (action) {
        case 'instance-start':
            await applyInstanceAction(instanceId, InstanceActionEnum.START);
            break;
        case 'instance-stop':
            await applyInstanceAction(instanceId, InstanceActionEnum.STOP);
            break;
        case 'instance-reboot':
            await applyInstanceAction(instanceId, InstanceActionEnum.REBOOT);
            break;
        case 'instance-terminate':
            await applyInstanceAction(instanceId, InstanceActionEnum.TERMINATE);
            break;
        case 'instance-hibernate':
            await applyInstanceAction(instanceId, InstanceActionEnum.HIBERNATE);
            break;
        default:
            console.warn(`Unknown instance action ${action}`);
            break;
    }
    callback();
    setLoadingState(false);
}

export async function performDCVAction(action: string, selectedItems: ReadonlyArray<InstanceInterface>, setLoadingState: { (value: SetStateAction<boolean>): void; (arg0: boolean): void; }, callback: { (): Promise<void>; (): void; }): Promise<void> {
    if (selectedItems.length !== 1) {
        return;
    }
    const instanceId = selectedItems[0].instanceId.toString();
    setLoadingState(true);
    switch (action) {
        case 'nice-dcv-server-download-connection-file':
            dcvDownloadConnectionFile(instanceId);
            break;
        case 'nice-dcv-server-generate-connection-string':
            dcvCopyConnectionString(instanceId);
            break;
        case 'nice-dcv-server-configure':
            await applyDCVAction(instanceId, DCVActionEnum.CONFIGURE);
            break;
        case 'nice-dcv-server-restart':
            await applyDCVAction(instanceId, DCVActionEnum.RESTART);
            break;
        case 'nice-dcv-server-create-credentials':
            await applyDCVAction(instanceId, DCVActionEnum.CREDENTIALS);
            break;
        default:
            console.warn(`Unknown DCV action ${action}`);
            break;
    }
    callback();
    setLoadingState(false);
}

const dcvCopyConnectionString = (instanceId: string) => {

    console.warn(`instanceId ${instanceId}`);

    const jwtToken = localStorage.getItem('jwtToken');

    if (navigator && navigator.clipboard && navigator.clipboard.writeText) {
        const str = `${aws_config.app_config.connectionGatewayLoadBalancerEndpoint}:${aws_config.app_config.connectionGatewayLoadBalancerPort}?authToken=${jwtToken}#${instanceId}`;
        return navigator.clipboard.writeText(str);
    }
};

const dcvDownloadConnectionFile = async (instanceId: string) => {
    const jwtToken = localStorage.getItem('jwtToken');
    const username = await getCurrentUserName();

    const file_link = document.createElement('a');
    const file_content = `
[connect]
host=${aws_config.app_config.connectionGatewayLoadBalancerEndpoint}
port=${aws_config.app_config.connectionGatewayLoadBalancerPort}
sessionid=${instanceId}
authtoken=${jwtToken}
user=${username}
weburlpath=

[version]
format=1.0
`;
    const file_blob = new Blob([file_content], { type: 'text/plain' });
    file_link.href = URL.createObjectURL(file_blob);
    file_link.download = `[${aws_config.app_config.prefix}]-[${username}]-dcv-connection-${instanceId}-${Date.now()}.dcv`;
    file_link.click();
}

export async function listInstances(includeTerminated: boolean = false): Promise<ApiResponseWrapper<{ items: InstanceInterface[] }, ApiErrorHandler>> {
    try {
        const restOperation = axios.get("api/portal/instances/list", {
            params: { includeTerminated: includeTerminated.toString() },
            headers: { "Content-Type": "application/json", "Authorization": `Bearer ${await getCurrentSessionJwtToken()}` },
        });
        const response = (await restOperation).data;
        return [{ items: response['instances'] }, undefined];
    } catch (error) {
        // Print out the actual error given back to us.
        console.error(error);
        await handleError(error);
        return [undefined, error];
    }
}

async function applyInstanceAction(instanceId: string, instanceAction: InstanceActionEnum): Promise<ApiResponseWrapper<{ items: InstanceInterface[] }, ApiErrorHandler>> {
    try {
        const restOperation = axios.post(`api/portal/instances/${instanceAction}`,
            { instanceIds: [`${instanceId}`], origin: "portal", },
            { headers: { "Content-Type": "application/json", "Authorization": `Bearer ${await getCurrentSessionJwtToken()}` }, }
        );
        const response = (await restOperation).data;
        return [{ items: response['instances'] }, undefined];
    } catch (error) {
        // Print out the actual error given back to us.
        console.error(error);
        await handleError(error);
        return [undefined, error];
    }
}

async function applyDCVAction(instanceId: string, dcvAction: DCVActionEnum): Promise<ApiResponseWrapper<{ items: InstanceInterface[] }, ApiErrorHandler>> {
    try {
        const restOperation = axios.post(`api/portal/dcv/configure`,
            { 
                instanceIds: [`${instanceId}`], 
                origin: "portal", 
                document: dcvAction
            },
            { headers: { "Content-Type": "application/json", "Authorization": `Bearer ${await getCurrentSessionJwtToken()}` }, }
        );
        const response = (await restOperation).data;
        return [{ items: response['instances'] }, undefined];
    } catch (error) {
        // Print out the actual error given back to us.
        console.error(error);
        await handleError(error);
        return [undefined, error];
    }
}

