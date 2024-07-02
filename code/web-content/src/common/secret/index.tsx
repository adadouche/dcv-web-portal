/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */
import { ReactNode, SetStateAction } from "react";
import { ApiErrorHandler, ApiResponseWrapper } from "../error";
import axios from "axios";
import { getCurrentSessionJwtToken, handleError } from "../cognito";

export async function getCurrentUserNameOSPassword(): Promise<ApiResponseWrapper<string, ApiErrorHandler>> {
    try {
        const restOperation = axios.get("api/portal/secret/get", {
            params: {},
            headers: { "Content-Type": "application/json", "Authorization": `Bearer ${await getCurrentSessionJwtToken()}` },
        });
        const response = (await restOperation).data;
        return [response.secretString, undefined];
    } catch (error) {
        // Print out the actual error given back to us.
        console.error(error);
        await handleError(error);
        return [undefined, error];
    }
}
