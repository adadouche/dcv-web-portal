window.global ||= window;

import * as ReactDOMClient from 'react-dom/client';
import App from './App.tsx'

import { I18nProvider, importMessages } from "@cloudscape-design/components/i18n";

import "@aws-amplify/ui-react/styles.css";
import '@cloudscape-design/global-styles/index.css';

import { translations } from '@aws-amplify/ui-react';
import { Amplify } from 'aws-amplify';
import { I18n } from 'aws-amplify/utils';
import { defaultStorage } from 'aws-amplify/utils';
import { cognitoUserPoolsTokenProvider } from 'aws-amplify/auth/cognito';

import vocabularies from "./i18n/vocabularies.ts";
import aws_config from './aws/aws-exports.js';

I18n.putVocabularies(translations);
I18n.putVocabularies(vocabularies);

const locale = document.documentElement.lang;
const messages = await importMessages(locale);

Amplify.configure(aws_config.config, aws_config.options);
cognitoUserPoolsTokenProvider.setKeyValueStorage(defaultStorage);

function registerServiceWorker() {
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
      // console.log("serviceWorker - addEventListener - load - started");
      const url = `service-worker.js`;
      navigator.serviceWorker
        .register(url)
        .then((registration) => {
          // console.log("serviceWorker - registration - then - started");
          registration.onupdatefound = () => {
            // console.log("serviceWorker - registration - onupdatefound - started");
            const installingWorker = registration.installing;
            if (installingWorker != null) {
              installingWorker.onstatechange = () => {
                if (installingWorker.state === "installed") {
                  if (navigator.serviceWorker.controller) {
                    console.log("serviceWorker - new version installed");
                  }
                }
              };
            }
            // console.log("serviceWorker - registration - onupdatefound - completed");
          };
          // console.log("serviceWorker - registration - then - completed");
        })
        .catch((error) => {
          console.error("serviceWorker registration error");
          console.error(error);
        });
        // console.log("serviceWorker - addEventListener - load - completed");
    });
  }
}
registerServiceWorker();

ReactDOMClient.createRoot(document.getElementById("root")).render(
  <I18nProvider locale={locale} messages={messages}>
    <App />
  </I18nProvider>
);

