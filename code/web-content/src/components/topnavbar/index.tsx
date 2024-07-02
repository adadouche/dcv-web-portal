/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */
import { I18n } from "@aws-amplify/core";
import {
  TopNavigation,
  Modal,
  Box,
  Button,
  SpaceBetween,
  Header,
  Table,
  Toggle,
  Grid,
} from "@cloudscape-design/components";
import { signOut } from 'aws-amplify/auth';
import { useNavigate } from "react-router-dom";
import { getCurrentUserName } from "../../common/cognito";
import { useEffect, useState } from "react";
import aws_config from '../../aws/aws-exports.js';
import { getCurrentUserNameOSPassword } from "../../common/secret";

function TopNavBar() {
  const [username, setUserName] = useState("");
  const [usernamePassword, setUserNamePassword] = useState("");
  const [usernamePasswordSaved, setUserNamePasswordSaved] = useState("");
  const [showAbout, setShowAbout] = useState(false);
  const [showSecurity, setShowSecurity] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const getSecretPassword = async (checked: boolean) => {
    if (checked) {
      setShowPassword(true);

      const [secretValue, error] = await getCurrentUserNameOSPassword();
      console.log("secretValue : " + secretValue)
      if (secretValue !== undefined && secretValue !== "") {
        setUserNamePassword(secretValue);
        setUserNamePasswordSaved(secretValue);
      }
      // }
    } else {
      setShowPassword(false);
      setUserNamePassword("*********");
    }
  }
  useEffect(() => {
    setUserNamePassword("*********")
    const getUserNameState = async () => {
      await getCurrentUserName().then((value => {
        setUserName(value)
      }));
    }
    getUserNameState();
    // getUserNamePasswordState();
  }, []);

  const navigate = useNavigate();


  function handleProfileClick(id: any): void {
    if (id === "signout") {
      signOut();
    }
    if (id === "about") {
      setShowAbout(true);
    }
    if (id === "security") {
      setShowSecurity(true);
    }
  }
  const profileActions = [
    { id: 'security', text: 'Security' },
    { id: 'about', text: 'About' },
    { id: 'signout', text: '', items: [
      { id: 'signout', text: 'Sign out' },
    ] },
  ];

  const tilte = I18n.get("NICE DCV Web Portal");
  const tilteAlt = "";
  return (
    <div id="navbar">
      <Modal
        onDismiss={() => setShowAbout(false)}
        visible={showAbout}
        closeAriaLabel="Close about box"
        footer={
          <Box float="right">
            {
              <SpaceBetween direction="horizontal" size="xs">
                <Button variant="link" onClick={() => setShowAbout(false)}>{I18n.get("Close")}</Button>
              </SpaceBetween>
            }
          </Box>
        }
      >
        <Table
          columnDefinitions={[
            {
              id: "Property",
              header: "Property",
              cell: item => item.property || "-",
              sortingField: "property",
              isRowHeader: true
            },
            {
              id: "Value",
              header: "Value",
              cell: item => item.value || "-",
              sortingField: "value"
            }
          ]}
          items={[
            {
              property: I18n.get('Deployment Mode'),
              value: I18n.get(aws_config.app_config.deploymentMode),
            },
            {
              property: I18n.get('Prefix'),
              value: I18n.get(aws_config.app_config.prefix),
            },
            {
              property: I18n.get('Project'),
              value: I18n.get(aws_config.app_config.project),
            },
            {
              property: I18n.get('Application'),
              value: I18n.get(aws_config.app_config.application),
            },
            {
              property: I18n.get('Environment'),
              value: I18n.get(aws_config.app_config.environment),
            },
          ]}
          sortingDisabled
          header={<Header> {I18n.get("About")} </Header>}
        />
      </Modal>
      <Modal
        onDismiss={() => setShowSecurity(false)}
        visible={showSecurity}
        closeAriaLabel="Close security box"
        footer={
          <Box float="right">
            {
              <SpaceBetween direction="horizontal" size="xs">
                <Button variant="link" onClick={() => setShowSecurity(false)}>{I18n.get("Close")}</Button>
              </SpaceBetween>
            }
          </Box>
        }
        header={I18n.get("Credentials")}
      >
        <SpaceBetween direction="vertical" size="xs">

          <Grid
            disableGutters
            gridDefinition={[
              { colspan: 5 },
              { colspan: 5 },
              { colspan: 5 },
              { colspan: 5 },
            ]}
          >
            <div>{I18n.get('OS user name')}</div>
            <div>{I18n.get(username)}</div>
            <div>{I18n.get('OS password')}</div>
            <div>{usernamePassword}</div>
          </Grid>

          <Toggle
            onChange={({ detail }) => getSecretPassword(detail.checked)}
            checked={showPassword}>
            Show password
          </Toggle>
        </SpaceBetween>
      </Modal>
      <TopNavigation
        identity={{
          href: "/",
          title: tilte,
          logo: {
            src: "data:image/svg+xml;base64,PHN2ZwogIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICB3aWR0aD0iNDIiCiAgaGVpZ2h0PSI0MiIKICBmaWxsPSIjZmZmZmZmIgogIHZpZXdCb3g9IjAgMCAxNiAxNiI+CiAgPHBhdGggZD0iTTggMWExIDEgMCAwIDEgMS0xaDZhMSAxIDAgMCAxIDEgMXYxNGExIDEgMCAwIDEtMSAxSDlhMSAxIDAgMCAxLTEtMVYxWm0xIDEzLjVhLjUuNSAwIDEgMCAxIDAgLjUuNSAwIDAgMC0xIDBabTIgMGEuNS41IDAgMSAwIDEgMCAuNS41IDAgMCAwLTEgMFpNOS41IDFhLjUuNSAwIDAgMCAwIDFoNWEuNS41IDAgMCAwIDAtMWgtNVpNOSAzLjVhLjUuNSAwIDAgMCAuNS41aDVhLjUuNSAwIDAgMCAwLTFoLTVhLjUuNSAwIDAgMC0uNS41Wk0xLjUgMkExLjUgMS41IDAgMCAwIDAgMy41djdBMS41IDEuNSAwIDAgMCAxLjUgMTJINnYyaC0uNWEuNS41IDAgMCAwIDAgMUg3di00SDEuNWEuNS41IDAgMCAxLS41LS41di03YS41LjUgMCAwIDEgLjUtLjVIN1YySDEuNVoiIC8+Cjwvc3ZnPg==",
            alt: tilteAlt,
          },
        }}
        utilities={[
          {
            type: "button",
            text: I18n.get("My Instances"),
            onClick: () => navigate("/my-instances"),
            external: false,
          },
          {
            type: "button",
            text: I18n.get("My Templates"),
            onClick: () => navigate("/my-templates"),
            external: false,
          },
          {
            type: 'menu-dropdown',
            text: username,
            iconName: 'user-profile',
            items: profileActions,
            onItemClick: ({ detail }) => handleProfileClick(detail.id),
          }
        ]}

        i18nStrings={{
          overflowMenuTriggerText: I18n.get("More"),
          overflowMenuTitleText: I18n.get("All"),
        }}
      />

    </div>
  );
}

export default TopNavBar;
