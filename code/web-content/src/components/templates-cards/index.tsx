/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */
import { useEffect, useState } from "react";

import {
  Button,
  Cards,
  ColumnLayout,
  Flashbar,
  FlashbarProps,
  Pagination,
  TextFilter,
} from "@cloudscape-design/components";
import { useCollection } from "@cloudscape-design/collection-hooks";
import SpaceBetween from "@cloudscape-design/components/space-between";

import {
  CardEmptyStateNoAction,
  CardHeader,
  CardNoMatchState,
} from "../../helper/card";
import { useNavigate } from "react-router-dom";
import { useLocalStorage } from "../../helper/local-storage";
import {
  getHeaderCounterText,
  getTextFilterCounterText,
} from "../../helper/i18n-strings";

import { CARD_DEFINITIONS, CARD_PREFERENCES } from "./config";
import { TemplateInterface, listTemplates } from "../../common/templates";
import { I18n } from 'aws-amplify/utils';

import { MyPreferences } from "../../helper/list";

import TemplateLaunchModal from "../modal/template-launch";

const cardHeaderTile = "Templates";
const cardActionTile = "Launch Instance from Template";

function TemplatesCard() {
  const navigate = useNavigate();

  const [data, setData] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  const [modalVisible, setModalVisible] = useState(false);

  const [flashItems, setFlashItems] = useState<FlashbarProps.MessageDefinition[]>([]);

  const [preferences, setPreferences] = useLocalStorage(
    "React-TemplateCard-Preferences",
    CARD_PREFERENCES
  );

  const { items, actions, filteredItemsCount, collectionProps, filterProps, paginationProps, } = useCollection(data, {
    filtering: {
      empty: <CardEmptyStateNoAction resourceName="Template" />,
      noMatch: (<CardNoMatchState onClearFilter={() => actions.setFiltering("")} />),
    },
    pagination: {
      pageSize: preferences.pageSize
    },
    selection: {
      keepSelection: false
    },
  });

  const [template, setTemplate] = useState<TemplateInterface>();

  const onTemplateLaunchClick = async () => {
    setTemplate(collectionProps.selectedItems[0]);
    setModalVisible(true);
    // setIsLoading(true);
  };

  const headerActions = (
    <SpaceBetween size="xs" direction="horizontal">
      <Button iconName="refresh" variant="icon" onClick={() => fetch()} />
      <Button
        data-testid="header-btn-create"
        disabled={isLoading || !(collectionProps.selectedItems.length === 1)}
        variant="primary"
        onClick={() => onTemplateLaunchClick()}
      >
        {I18n.get(cardActionTile)}
      </Button>
    </SpaceBetween>
  );

  const listItems = async () => {
    setIsLoading(true);
    // let intervalId: NodeJS.Timer = setInterval(async () => {
    const [response, error] = await listTemplates();
    if (response === undefined) {
      const message: FlashbarProps.MessageDefinition = {
        type: "error",
        content: `There was a problemn listing templates : ${error.message}`,
        dismissible: true,
        dismissLabel: "Dismiss message",
        onDismiss: () => setFlashItems([]), id: "message_2"
      };
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
    listItems();
  };

  useEffect(() => {
    fetch();
  }, []);

  return (
    <>
      <Flashbar items={flashItems} />
      {template &&
        <TemplateLaunchModal
          template={template}
          isVisible={modalVisible}
          setIsVisible={setModalVisible}
          setFlashItems={setFlashItems}
          />
      }
      <Cards
        {...collectionProps}
        cardDefinition={CARD_DEFINITIONS}
        visibleSections={preferences.visibleContent}
        items={items}
        selectionType="single"
        loading={isLoading}
        stickyHeader={true}
        trackBy="id"
        entireCardClickable={true}
        filter={
          <ColumnLayout columns={2}>
            <TextFilter
              {...filterProps}
              countText={getTextFilterCounterText(filteredItemsCount)}
              disabled={isLoading}
            />
          </ColumnLayout>
        }
        header={
          <CardHeader
            actions={headerActions}
            selectedItemsCount={collectionProps.selectedItems.length}
            title={I18n.get(cardHeaderTile)}
            counter={!isLoading && getHeaderCounterText(data, collectionProps.selectedItems)}
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
export default TemplatesCard;