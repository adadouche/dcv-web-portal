/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */

import { I18n } from 'aws-amplify/utils';
import { TableProps } from "@cloudscape-design/components/table";
import {
  DEFAULT_PREFERENCES,
  DEFAULT_VISIBLE_CONTENT,
  createTableSortLabelFn,
} from "../../helper/table";
import StatusIndicator from "@cloudscape-design/components/status-indicator";
import { InstanceInterface, getDCVStatusIndicator, getInstanceStateIndicator, getInstanceStatusCheckIndicator } from "../../common/instance";

const _DEFAULT_VISIBLE_CONTENT = [
  ...DEFAULT_VISIBLE_CONTENT,
  "instanceState",
  "instanceStatusCheck",
  "dcvStatus",
  "instanceType",
];

export const TABLE_COLUMN_DEFINTION: ReadonlyArray<
  TableProps.ColumnDefinition<InstanceInterface>
> = [
  {
    id: "instanceId",
    header: I18n.get("Instance Id"),
    cell: (item) => item.instanceId || "*",
  },
  {
    id: "name",
    header: I18n.get("Instance Name"),
    cell: (item) => item.name || "*",
  },
  {
    id: "instanceState",
    header: I18n.get("Instance State"),
    cell: (item) => (
      <StatusIndicator type={getInstanceStateIndicator(item.instanceState)}>
        &nbsp;{I18n.get(item.instanceState)}
      </StatusIndicator>
    ),
  },
  {
    id: "instanceStatusCheck",
    header: I18n.get("Status Check"),
    cell: (item) => (
      <StatusIndicator type={getInstanceStatusCheckIndicator(item.instanceStatusCheck)}>
        &nbsp;{I18n.get(item.instanceStatusCheck)}
      </StatusIndicator>
    ),
  },
  {
    id: "dcvStatus",
    header: I18n.get("DCV Status"),
    cell: (item) => (
      <StatusIndicator type={getDCVStatusIndicator(item.dcvStatus)}>
        &nbsp;{I18n.get(item.dcvStatus)}
      </StatusIndicator>
    ),
  },
  {
    id: "username",
    header: I18n.get("User Name"),
    cell: (item) => item.username || "",
  },
  {
    id: "createdAt",
    header: I18n.get("Creation Time"),
    cell: (item) => item.createdAt || "",
  },
  {
    id: "createdBy",
    header: I18n.get("Created By"),
    cell: (item) => item.createdBy || "",
  },
  {
    id: "launchTemplateId",
    header: I18n.get("Template Id"),
    cell: (item) => item.launchTemplateId,
  },
  {
    id: "launchTemplateName",
    header: I18n.get("Template Name"),
    cell: (item) => item.launchTemplateName,
  },
  {
    id: "launchTemplateVersion",
    header: I18n.get("Template Version"),
    cell: (item) => item.launchTemplateVersion,
  },
  {
    id: "instanceFamily",
    header: I18n.get("Instance Family"),
    cell: (item) => item.instanceFamily,
  },
  {
    id: "instanceSize",
    header: I18n.get("Instance Size"),
    cell: (item) => item.instanceSize,
  },
  {
    id: "instanceType",
    header: I18n.get("Instance Type"),
    cell: (item) => item.instanceType,
  },
  {
    id: "osFamily",
    header: I18n.get("OS Family"),
    cell: (item) => item.osFamily,
  },
  {
    id: "osPlatform",
    header: I18n.get("OS Platform"),
    cell: (item) => item.osPlatform,
  },
].map((column) => ({
  ...column,
  ariaLabel: createTableSortLabelFn(column),
}));


const COLUMN_DISPLAY: ReadonlyArray<TableProps.ColumnDisplayProperties> = 
  TABLE_COLUMN_DEFINTION.map((column) => ({ id: column.id, visible: (_DEFAULT_VISIBLE_CONTENT.includes(column.id) ? true : false) }));

export const TABLE_PREFERENCES = {
  ...DEFAULT_PREFERENCES,
  contentDisplay: COLUMN_DISPLAY,
  contentDisplayPreference: {
    options: TABLE_COLUMN_DEFINTION.map((column) => ({
      id: column.id,
      label: column.header,
    })),
  }
};

