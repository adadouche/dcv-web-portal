/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */
import { AuthTokens, fetchAuthSession, getCurrentUser, signOut } from "aws-amplify/auth";
import { Hub } from 'aws-amplify/utils';

export interface CognitoUser {
    signInDetails?: {
        loginId?: string;
        authFlowType?: 'USER_SRP_AUTH' | 'CUSTOM_WITH_SRP' | 'CUSTOM_WITHOUT_SRP' | 'USER_PASSWORD_AUTH';
    },
    username?: string;
    userId?: string;
}

export interface CognitoSession {
    tokens?: AuthTokens;
    credentials?: {
        accessKeyId: string;
        secretAccessKey: string;
        sessionToken?: string;
        expiration?: Date;
    },
    identityId?: string;
    userSub?: string;
}

Hub.listen('auth', async ({ payload }) => {
    switch (payload.event) {
        case 'signedIn':
            clearSessionStorage();
            await loadLocalStorage();
            break;
        case 'signedOut':
            localStorage.clear();
            break;
        case 'tokenRefresh':
            clearSessionStorage();
            await loadLocalStorage();
            break;
        case 'tokenRefresh_failure':
            clearSessionStorage();
            await signOut();
            break;
        case 'signInWithRedirect':
            clearSessionStorage();
            await loadLocalStorage();
            break;
        case 'signInWithRedirect_failure':
            clearSessionStorage();
            await signOut();
            break;
        case 'customOAuthState':
            console.log('custom state returned from CognitoHosted UI');
            break;
    }
});

async function getCurrentAuthenticatedUser() {
    try {
        const { username, userId, signInDetails } = await getCurrentUser();
        localStorage.setItem('username', `${username}`);
        localStorage.setItem('userId', `${userId}`);
        localStorage.setItem('signInDetails', `${signInDetails}`);
    } catch (err) {
        console.log(err);
    }
}

async function getCurrentSession() {
    try {
        const { accessToken, idToken } = (await fetchAuthSession()).tokens ?? {};
        localStorage.setItem('accessToken', `${accessToken}`);
        localStorage.setItem('idToken', `${idToken}`);
        localStorage.setItem('jwtToken', `${idToken}`);
        localStorage.setItem('groups', `${idToken.payload["cognito:groups"]}`);
    } catch (err) {
        console.log(err);
    }
}

async function loadLocalStorage() {
    try {
        await getCurrentSession();
        await getCurrentAuthenticatedUser();
    } catch (err) {
        console.log(err);
    }
}

function clearSessionStorage() {
    try {
        localStorage.removeItem('accessToken');
        localStorage.removeItem('idToken');
        localStorage.removeItem('jwtToken');
        localStorage.removeItem('groups');

        localStorage.removeItem('username');
        localStorage.removeItem('userId');
        localStorage.removeItem('signInDetails');
    } catch (err) {
        console.log(err);
    }
}

async function getLocalStorageKey(key: string) {
    try {
        if (localStorage.getItem(key) === undefined || localStorage.getItem(key) === null) {
            await loadLocalStorage();
        }
        return localStorage.getItem(key);
    } catch (err) {
        console.log(err);
    }
}

export async function getCurrentSessionAccessToken() {
    const key = "accessToken";
    return getLocalStorageKey(key);
}

export async function getCurrentSessionJwtToken() {
    const key = "idToken";
    return getLocalStorageKey(key);
}

export async function getCurrentSessionIdToken() {
    const key = "idToken";
    return getLocalStorageKey(key);
}

export async function getCurrentUserName() {
    const key = "username";
    return getLocalStorageKey(key);
}

export async function handleError(error) {
    if(error['response']['status'] === 401 && error['response']['data']['message'] === 'The incoming token has expired' ) {
        await signOut()
    }
}