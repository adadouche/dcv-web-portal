/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */

import { I18n } from 'aws-amplify/utils';
import Link from "@cloudscape-design/components/link";
import {
  DEFAULT_PAGE_SIZE_PREFERENCES,
  DEFAULT_PREFERENCES,
  DEFAULT_VISIBLE_CONTENT,
} from "../../helper/card";
import { CollectionPreferencesProps } from "@cloudscape-design/components/collection-preferences";

export const CARD_DEFINITIONS = {
  header: (item) => (
    <div>
      {item.name}
    </div>
  ),
  sections: [
    {
      id: "id",
      header: I18n.get("Identifier"),
      content: (item) => item.id || "*",
    },
    {
      id: "description",
      header: I18n.get("Description"),
      content: (item) => item.description || "*",
    },
    {
      id: "createdAt",
      header: I18n.get("Creation Time"),
      content: (item) => item.createdAt || "",
    },
    {
      id: "createdBy",
      header: I18n.get("Created By"),
      content: (item) => item.createdBy || "",
    },
    {
      id: "defaultVersion",
      header: I18n.get("Default Template Version"),
      content: (item) => item.defaultVersion,
    },
    {
      id: "latestVersion",
      header: I18n.get("Latest Template Version"),
      content: (item) => item.latestVersion,
    },
    {
      id: "osFamily",
      header: I18n.get("OS Family"),
      content: (item) => item.osFamily,
    },
    {
      id: "osPlatform",
      header: I18n.get("OS Platform"),
      content: (item) => item.osPlatform,
    },
    {
      id: "osVersion",
      header: I18n.get("OS Version"),
      content: (item) => item.osVersion,
    },
    {
      id: "components",
      header: I18n.get("Installed components"),
      content: (item) => {const rows = []; const _items = item.components.split(','); for (let i = 0; i < _items.length; i++) {rows.push(<div> - {_items[i]}</div>);}; return rows;}
    },
    {
      id: "policies",
      header: I18n.get("Assigned policies"),
      content: (item) => {const rows = []; const _items = item.policies.split(','); for (let i = 0; i < _items.length; i++) {rows.push(<div> - {_items[i]}</div>);}; return rows;}
    },
    {
      id: "instanceFamilies",
      header: I18n.get("Instance Families"),
      content: (item) => {const rows = []; const _items = item.instanceFamilies; for (let i = 0; i < _items.length; i++) {rows.push(<div> - {_items[i]}</div>);}; return rows;}
    },
    {
      id: "instanceSizes",
      header: I18n.get("Instance Sizes"),
      content: (item) => {const rows = []; const _items = item.instanceSizes; for (let i = 0; i < _items.length; i++) {rows.push(<div> - {_items[i]}</div>);}; return rows;}
    },

    {
      id: "volumeType",
      header: I18n.get("Volume Type"),
      content: (item) => item.volumeType,
    },
    {
      id: "volumeSize",
      header: I18n.get("Volume Size"),
      content: (item) => item.volumeSize,
    },
  ],
};

const CARD_DEFAULT_VISIBLE_CONTENT = [
  ...DEFAULT_VISIBLE_CONTENT,
  "id",
  "description",

  "osFamily",
  "osPlatform",
  "osVersion",

  "instanceFamilies",
  "instanceSizes",
];

export const CARD_CONTENT_DISPLAY: ReadonlyArray<CollectionPreferencesProps.VisibleContentOption> =
  CARD_DEFINITIONS.sections.map((column) => ({
    id: column.id,
    label: column.header,
  }));

// visible: (CARD_DEFAULT_VISIBLE_CONTENT.includes(column.id) ? true : false)
const VISIBLE_CONTENT_OPTIONS: ReadonlyArray<CollectionPreferencesProps.VisibleContentOptionsGroup> =
  [
    {
      label: "",
      options: CARD_DEFINITIONS.sections.map((column) => ({
        id: column.id,
        label: column.header,
      })),
    },
  ];

// export const VISIBLE_CONTENT_OPTIONS = [

export const CARD_PREFERENCES = {
  ...DEFAULT_PREFERENCES,
  cardDefinition: CARD_DEFINITIONS,
  visibleContent: CARD_DEFAULT_VISIBLE_CONTENT,
  visibleContentPreference: {
    title: I18n.get("Select visible columns"),
    options: VISIBLE_CONTENT_OPTIONS,
  }
};