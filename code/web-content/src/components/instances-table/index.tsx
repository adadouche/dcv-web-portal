/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */
import { useEffect, useState } from "react";

import Table from "@cloudscape-design/components/table";
import { Button, ButtonDropdown, ColumnLayout, Flashbar, FlashbarProps, TextFilter, Toggle } from "@cloudscape-design/components";
import { useCollection } from '@cloudscape-design/collection-hooks';
import SpaceBetween from "@cloudscape-design/components/space-between";
import Pagination from "@cloudscape-design/components/pagination";

import {
  TableHeader,
} from "../../helper/table";
import { useNavigate } from "react-router-dom";
import { useLocalStorage } from "../../helper/local-storage";

import {
  getHeaderCounterText,
  getTextFilterCounterText,
} from "../../helper/i18n-strings";

import { TABLE_COLUMN_DEFINTION, TABLE_PREFERENCES } from "./config";
import { canStartDCVSession, isNotRunningInstance, isNotTerminatedInstance, isRunningInstance, listInstances, performInstanceAction, performDCVAction, canConfigureDCVSession, InstanceInterface } from "../../common/instance";
import { I18n } from 'aws-amplify/utils';
import { MyPreferences, useColumnWidths } from "../../helper/list";
import { TableEmptyStateNoAction, TableNoMatchState } from "../../helper/table";
import { download_links } from "../../../export/aws-config";

const tableHeaderTile = 'Instances'

function InstancesTable() {
  const [data, setData] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  const [flashItems, setFlashItems] = useState<FlashbarProps.MessageDefinition[]>([]);
  const [includeTerminated, setIncludeTerminated] = useState(false);

  const navigate = useNavigate();

  const download_items = [];

  for (const [key, value] of Object.entries(download_links).sort()) {
    download_items.push(
      { id: `nice-dcv-server-download-${key}`, external: true, href: `downloads/${key}/${value.filename}`, text: key }
    );
  }

  const listItems = async () => {
    setIsLoading(true);
    // let intervalId: NodeJS.Timer = setInterval(async () => {
    const [response, error] = await listInstances(includeTerminated);
    if (response === undefined) {
      const message: FlashbarProps.MessageDefinition = { type: "error", content: `There was a problemn listing instances : ${error.message}`, dismissible: true, dismissLabel: "Dismiss message", onDismiss: () => setFlashItems([]), id: "message_2" };
      setFlashItems([
        message
      ])
    } else {
      setData(response.items);
    }
    // }, 5 * 1000);
    setIsLoading(false);
  }

  const fetch = async () => {
    await listItems();
  };

  useEffect(() => {
    fetch();
  }, [])

  useEffect(() => {
    fetch();
  }, [includeTerminated]);

  const setToggleIncludeTerminated = async (_includeTerminated: boolean) => {
    setIncludeTerminated(_includeTerminated);
  };

  const [preferences, setPreferences] = useLocalStorage(
    "React-InstanceTable-Preferences",
    TABLE_PREFERENCES
  );

  const [COLUMN_DEFINTION, saveWidths] = useColumnWidths(
    "React-InstanceTable-Widths",
    TABLE_COLUMN_DEFINTION
  );

  const { items, actions, filteredItemsCount, collectionProps, filterProps, paginationProps, } = useCollection(data, {
    filtering: {
      empty: <TableEmptyStateNoAction resourceName={"Instance"} />,
      noMatch: (<TableNoMatchState onClearFilter={() => actions.setFiltering("")} />),
    },
    pagination: { pageSize: preferences.pageSize },
    selection: {},
  });

  const headerActions =
    <SpaceBetween size="xs" direction="horizontal">
      <Button iconName="refresh" variant="icon" onClick={() => fetch()} />
      <ButtonDropdown disabled={!(isNotTerminatedInstance(collectionProps.selectedItems))}
        onItemClick={({ detail }) => performInstanceAction(detail.id, collectionProps.selectedItems, setIsLoading, listItems)}
        items={[
          { id: "instance-start", text: I18n.get("Start"), disabled: !(isNotRunningInstance(collectionProps.selectedItems)) },
          { id: "instance-stop", text: I18n.get("Stop"), disabled: !(isRunningInstance(collectionProps.selectedItems)) },
          // { id: "instance-hibernate", text: I18n.get("Hibernate"), disabled: !(isRunningInstance(collectionProps.selectedItems)) },
          // { id: "instance-reboot", text: I18n.get("Reboot"), disabled: !(isRunningInstance(collectionProps.selectedItems)) },
          { id: "instance-terminate", text: I18n.get("Terminate"), disabled: !(isNotTerminatedInstance(collectionProps.selectedItems)) },
        ]}
        variant="primary"
      >
        {I18n.get("Instance Actions")}
      </ButtonDropdown>
      <ButtonDropdown disabled={!(canConfigureDCVSession(collectionProps.selectedItems))}
        onItemClick={({ detail }) => performDCVAction(detail.id, collectionProps.selectedItems, setIsLoading, listItems)}
        items={[
          { id: "nice-dcv-server-create-credentials", text: I18n.get("Recreate user OS credentials"), disabled: !(isRunningInstance(collectionProps.selectedItems)) },
          { id: "nice-dcv-server-configure", text: I18n.get("Reconfigure NICE DCV Service"), disabled: !(isRunningInstance(collectionProps.selectedItems)) },
          { id: "nice-dcv-server-restart", text: I18n.get("Restart NICE DCV Service"), disabled: !(isRunningInstance(collectionProps.selectedItems)) },
        ]}
        variant="primary"
      >
        {I18n.get("DCV Engine Actions")}
      </ButtonDropdown>
      <ButtonDropdown disabled={!(canStartDCVSession(collectionProps.selectedItems))}
        onItemClick={({ detail }) => performDCVAction(detail.id, collectionProps.selectedItems, setIsLoading, listItems)}
        items={[
          { id: "nice-dcv-server-download-connection-file", iconName: "file", text: I18n.get("Download connection file"), },
          { id: "nice-dcv-server-generate-connection-string", iconName: "copy", text: I18n.get("Generate connection string"), },
        ]}
        variant="primary"
      >
        {I18n.get("Connect with NICE DCV")}
      </ButtonDropdown>
      <ButtonDropdown
        items={download_items}
        variant="primary"
      >
        {I18n.get("Download NICE DCV Client")}
      </ButtonDropdown>
    </SpaceBetween >

  return (
    <>
      <Flashbar items={flashItems} />
      <Table
        {...collectionProps}
        columnDefinitions={COLUMN_DEFINTION}
        columnDisplay={preferences.contentDisplay}
        items={items}
        selectionType="single"
        loading={isLoading}
        stickyHeader={true}
        resizableColumns={true}
        onColumnWidthsChange={saveWidths}
        wrapLines={preferences.wrapLines}
        stripedRows={preferences.stripedRows}
        contentDensity={preferences.contentDensity}
        stickyColumns={preferences.stickyColumns}
        trackBy="instanceId"
        filter={
          <>
            <ColumnLayout columns={2}>
              <TextFilter
                {...filterProps}
                countText={getTextFilterCounterText(filteredItemsCount)}
                disabled={isLoading} />
              <Toggle onChange={({ detail }) => { setToggleIncludeTerminated(detail.checked); }} checked={includeTerminated}>
                {I18n.get('Include recently terminated instances')}
              </Toggle>
            </ColumnLayout>
          </>
        }
        header={
          <TableHeader
            actions={headerActions}
            title={tableHeaderTile}
            selectedItemsCount={collectionProps.selectedItems.length}
            counter={getHeaderCounterText(
              data,
              collectionProps.selectedItems
            )}
          />
        }
        pagination={<Pagination {...paginationProps} disabled={isLoading} />}
        preferences={
          <MyPreferences
            preferences={preferences}
            setPreferences={setPreferences}
          />
        }
      />
    </>
  );
}

export default InstancesTable;


