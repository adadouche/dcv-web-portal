/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */

import {
  HeaderProps,
  Header,
  Box,
  Button,
  SpaceBetween,
} from "@cloudscape-design/components";
import { I18n } from 'aws-amplify/utils';
import { DEFAULT_VISIBLE_CONTENT_LIST } from "../list";

export const DEFAULT_PAGE_SIZE_PREFERENCES = {
  options: [
    { value: 8, label: "8 items" },
    { value: 16, label: "16 items" },
    { value: 24, label: "24 items" },
    { value: 32, label: "32 items" },
  ],
};

export const DEFAULT_VISIBLE_CONTENT = [...DEFAULT_VISIBLE_CONTENT_LIST]

export const DEFAULT_PREFERENCES = {
  pageSize: 8,
  pageSizePreference: DEFAULT_PAGE_SIZE_PREFERENCES,
  visibleContent: DEFAULT_VISIBLE_CONTENT,
};

interface CardHeaderProps extends HeaderProps {
  title?: string;
  createButtonText?: string;
  extraActions?: React.ReactNode;
  selectedItemsCount: number;
  onInfoLinkClick?: () => void;
}

export function CardHeader({
  title,
  actions,
  selectedItemsCount,
  ...props
}: CardHeaderProps) {
  return (
    <Header variant="awsui-h1-sticky" actions={actions} {...props}>
      {title}
    </Header>
  );
}

export const CardEmptyState = ({ resourceName }: { resourceName: string }) => (
  <Box margin={{ vertical: "xs" }} textAlign="center" color="inherit">
    <SpaceBetween size="xxs">
      <div>
      <b>{I18n.get("No " + resourceName.toLowerCase())}</b>
        <Box variant="p" color="inherit">
          {I18n.get("No " + resourceName.toLowerCase() + " associated with your profile")}
        </Box>
      </div>
      <Button>Create {resourceName.toLowerCase()}</Button>
    </SpaceBetween>
  </Box>
);

export const CardEmptyStateNoAction = ({
  resourceName,
}: {
  resourceName: string;
}) => (
  <Box margin={{ vertical: "xs" }} textAlign="center" color="inherit">
    <SpaceBetween size="xxs">
      <div>
        <b>{I18n.get("No " + resourceName.toLowerCase())}</b>
        <Box variant="p" color="inherit">
          {I18n.get("No " + resourceName.toLowerCase() + " associated with your profile")}
        </Box>
      </div>
    </SpaceBetween>
  </Box>
);

export const CardErrortate = () => (
  <Box margin={{ vertical: "xs" }} textAlign="center" color="inherit">
    <SpaceBetween size="xxs">
      <div>
        <b>{I18n.get("Error")}</b>
        <Box variant="p" color="inherit">
          We experienced an error while calling the backend.
        </Box>
      </div>
    </SpaceBetween>
  </Box>
);

export const CardNoMatchState = ({
  onClearFilter,
}: {
  onClearFilter: () => void;
}) => (
  <Box margin={{ vertical: "xs" }} textAlign="center" color="inherit">
    <SpaceBetween size="xxs">
      <div>
        <b>{I18n.get("No matches")}</b>
        <Box variant="p" color="inherit">
          We can't find a match.
        </Box>
      </div>
      <Button onClick={onClearFilter}>Clear filter</Button>
    </SpaceBetween>
  </Box>
);
