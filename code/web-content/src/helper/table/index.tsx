/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */

import {
  TableProps,
  Box,
  SpaceBetween,
  Button,
  HeaderProps,
  Header,
} from "@cloudscape-design/components";
import { I18n } from "aws-amplify/utils";
import { DEFAULT_VISIBLE_CONTENT_LIST } from "../list";

const contentDensity: "comfortable" | "compact" = "comfortable";

export const DEFAULT_PAGE_SIZE_PREFERENCES = {
  options: [
    { value: 5, label: "5 items" },
    { value: 10, label: "10 items" },
    { value: 30, label: "30 items" },
    { value: 50, label: "50 items" },
  ],
};

export const DEFAULT_VISIBLE_CONTENT = [...DEFAULT_VISIBLE_CONTENT_LIST];

export const DEFAULT_PREFERENCES = {
  pageSize: 10,
  pageSizePreference: DEFAULT_PAGE_SIZE_PREFERENCES,
  wrapLines: false,
  stripedRows: false,
  contentDensity: contentDensity,
  stickyColumns: {},
  disabled: false,
  wrapLinesPreference: {},
  stripedRowsPreference: {},
  contentDensityPreference: {},
  contentDisplayPreference: {},
  visibleContentPreference: {},
  stickyColumnsPreference: {},
};

interface TableHeaderProps extends HeaderProps {
  title?: string;
  createButtonText?: string;
  extraActions?: React.ReactNode;
  selectedItemsCount: number;
  onInfoLinkClick?: () => void;
}

export function TableHeader({
  title,
  actions,
  selectedItemsCount,
  ...props
}: TableHeaderProps) {
  return (
    <Header variant="awsui-h1-sticky" actions={actions} {...props}>
      {title}
    </Header>
  );
}

export function createTableSortLabelFn(
  column: TableProps.ColumnDefinition<unknown>
): TableProps.ColumnDefinition<unknown>["ariaLabel"] {
  if (!column.sortingField && !column.sortingComparator && !column.ariaLabel) {
    return;
  }
  return ({ sorted, descending }) => {
    return `${column.header}, ${
      sorted
        ? `sorted ${descending ? "descending" : "ascending"}`
        : "not sorted"
    }.`;
  };
}

export const baseTableAriaLabels: TableProps.AriaLabels<unknown> = {
  allItemsSelectionLabel: () => "select all",
};

export const baseEditableLabels: TableProps.AriaLabels<{ id: string }> = {
  activateEditLabel: (column, item) => `Edit ${item.id} ${column.header}`,
  cancelEditLabel: (column) => `Cancel editing ${column.header}`,
  submitEditLabel: (column) => `Submit edit ${column.header}`,
};

export const renderAriaLive: TableProps["renderAriaLive"] = ({
  firstIndex,
  lastIndex,
  totalItemsCount,
}) => `Displaying items ${firstIndex} to ${lastIndex} of ${totalItemsCount}`;

export const addToColumnDefinitions = (
  columnDefinitions,
  propertyName,
  columns
) =>
  columnDefinitions.map((colDef) => {
    const column = (columns || []).find((col) => col.id === colDef.id);
    return {
      ...colDef,
      [propertyName]: (column && column[propertyName]) || colDef[propertyName],
    };
  });

export const mapWithColumnDefinitionIds = (
  columnDefinitions,
  propertyName,
  items
) =>
  columnDefinitions.map(({ id }, i) => ({
    id,
    [propertyName]: items[i],
  }));

export const TableEmptyState = ({ resourceName }: { resourceName: string }) => (
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

export const TableEmptyStateNoAction = ({
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

export const TableErrortate = () => (
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

export const TableNoMatchState = ({
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
