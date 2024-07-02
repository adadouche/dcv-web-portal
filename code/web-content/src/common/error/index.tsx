// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

export interface ApiErrorHandler {
    userId?: string;
    message?: string
};

export type ApiResponseWrapper<T, E extends ApiErrorHandler> = [T, undefined] | [undefined, E];
