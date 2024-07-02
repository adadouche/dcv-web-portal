/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */

import { I18n } from "@aws-amplify/core";
import { Alert, Button, Container, Header } from "@cloudscape-design/components";

export default function NotFound() {
  return (
    <>
      <div className="content">
        <div className="main">
          <Container header={<Header variant="h1">404. {I18n.get("Not Found")}</Header>}>
            <Alert dismissAriaLabel={I18n.get("Close alert")} type="error" header="404">
              {I18n.get("Sorry, but the page you are looking for does not exist.")}
            </Alert>
            <Button href="/">{I18n.get("Back home")}</Button>
          </Container>
        </div>
      </div>
      <br />
    </>
  );
}
