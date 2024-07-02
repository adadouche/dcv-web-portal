/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */
import { AppLayout, BreadcrumbGroup } from "@cloudscape-design/components";
import TemplatesCards from "../../components/templates-cards";
import { I18n } from "aws-amplify/utils";

export default function Templates(): JSX.Element {
  return (
    <>
      <AppLayout
        contentType="table"
        content={
          <>
            <span> &nbsp; </span>
            {<TemplatesCards />}
          </>
        }
        headerSelector="navbar"
        navigationHide={true}
        toolsHide={true}
        breadcrumbs={
          <BreadcrumbGroup
            items={[
              { text: I18n.get("NICE DCV Web Portal"), href: "/" },
              { text: I18n.get("Templates"), href: "#" },
            ]}
          />
        }
      />
    </>
  );
}
