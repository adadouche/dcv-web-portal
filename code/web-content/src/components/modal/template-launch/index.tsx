/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */
/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */

import { Dispatch, FunctionComponent, SetStateAction, useState } from 'react';
import { Button, Input } from '@aws-amplify/ui-react';

import Modal from '@cloudscape-design/components/modal';
import { Box, SpaceBetween, Container, Header, FormField, Textarea, Select, Grid, Form, FlashbarProps } from '@cloudscape-design/components';
import { I18n } from 'aws-amplify/utils';
import { TemplateInterface, TemplateLaunchParametersInterface, TemplateLaunchParametersValidationInterface, launchTemplate } from '../../../common/templates';
import Slider from '@mui/material/Slider';
import { useNavigate } from 'react-router-dom';

type Dispatcher<S> = Dispatch<SetStateAction<S>>;

const fieldValidation = ["instanceName", "instanceDescription"];

interface TemplateLaunchModalProps {
  template: TemplateInterface;
  isVisible: boolean;
  setIsVisible: Dispatcher<boolean>;
  setFlashItems: Dispatcher<FlashbarProps.MessageDefinition[]>;
}

const TemplateLaunchModal: FunctionComponent<TemplateLaunchModalProps> = (props: TemplateLaunchModalProps) => {

  const navigate = useNavigate();

  const [modalConfirmed, setModalConfirmed,] = useState(false);
  const [formError, setFormError] = useState({});

  const [templateLaunchParameters, setTemplateLaunchParameters] = useState<TemplateLaunchParametersInterface>({
    instanceName: "",
    instanceDescription: "",

    templateName: props.template.name,
    launchTemplateId: props.template.id,
    launchTemplateVersion: props.template.defaultVersion,

    instanceType: `${props.template.instanceFamilies[0]}.${props.template.instanceSizes[0]}`,

    volumeType: props.template.volumeType,
    volumeSize: props.template.volumeSize,
    volumeIops: props.template.volumeIops,
    volumeThroughput: props.template.volumeThroughput,
  });

  const [templateLaunchhValidation, setTemplateLaunchhValidation] = useState<TemplateLaunchParametersValidationInterface>({
    volumeSizeMin: props.template.volumeSizeMin,
    volumeSizeMax: props.template.volumeSizeMax,

    volumeIopsMin: props.template.volumeIopsMin,
    volumeIopsMax: props.template.volumeIopsMax,

    volumeThroughputMin: props.template.volumeThroughputMin,
    volumeThroughputMax: props.template.volumeThroughputMax,

    instanceNameMin: 3,
    instanceNameMax: 64,
    instanceNamePattern: "a-zA-Z0-9_-",

    instanceDescriptionMin: 0,
    instanceDescriptionMax: 254,
    instanceDescriptionPattern: "a-zA-Z0-9_- :",
  });

  if (templateLaunchParameters.templateName !== props.template.name) {
    setFormError({});
    setTemplateLaunchParameters({
      ...templateLaunchParameters,
      instanceName: "",
      instanceDescription: "",

      templateName: props.template.name,
      launchTemplateId: props.template.id,
      launchTemplateVersion: props.template.defaultVersion,

      instanceType: `${props.template.instanceFamilies[0]}.${props.template.instanceSizes[0]}`,

      volumeType: props.template.volumeType,
      volumeSize: props.template.volumeSize,
      volumeIops: props.template.volumeIops,
      volumeThroughput: props.template.volumeThroughput,
    });

    setTemplateLaunchhValidation({
      ...templateLaunchhValidation,
      volumeSizeMin: props.template.volumeSizeMin,
      volumeSizeMax: props.template.volumeSizeMax,

      volumeIopsMin: props.template.volumeIopsMin,
      volumeIopsMax: props.template.volumeIopsMax,

      volumeThroughputMin: props.template.volumeThroughputMin,
      volumeThroughputMax: props.template.volumeThroughputMax,
    });
  }

  let instanceTypeListSelect = [];
  if (props.template !== undefined) {
    for (let i = 0; i < props.template.instanceFamilies.length; i++) {
      for (let j = 0; j < props.template.instanceSizes.length; j++) {
        let tmp = `${props.template.instanceFamilies[i]}.${props.template.instanceSizes[j]}`
        instanceTypeListSelect.push({ label: tmp, value: tmp });
      }
    }
  }

  const onChangeFormInputHandle = (name: string, value: unknown) => {
    setTemplateLaunchParameters({
      ...templateLaunchParameters,
      [name]: (value)
    });
  }

  const getFormFieldErrorText = (value: string, min_length: number, max_length: number, pattern: string = "") => {
    if (value.length < min_length) {
      return `Value length is below minimun (min: ${min_length}, current: ${value.length})`;
    }
    if (value.length > max_length) {
      return `Value length is above maximun (max: ${max_length}, current: ${value.length})`;
    }

    if (value.length > 0) {
      console.log(pattern)
      if (pattern !== "") {
        let regex = new RegExp(`^[${pattern}]+$`);
        let result = regex.test(value);
        if (!result) {
          return `Value is not valid (pattern: ${pattern})`;
        }

      }
    }
    return;
  }

  const getFormFieldErrorNumber = (value: number, min_value: number, max_value: number) => {
    const num = +value;
    if (isNaN(num)) {
      return "Value is not a number";
    }
    if (num < min_value) {
      return `Value is below minimun value (min: ${min_value}, current: ${num})`;
    }
    if (num > max_value) {
      return `Value is above maximun value (max: ${max_value}, current: ${num})`;
    }
    return;
  }

  const onDismissModal = async () => {
    setModalConfirmed(false)
    props.setIsVisible(false);
  };

  const onConfirmModal = async () => {
    let hasErrors = false;
    let errors = {};

    setModalConfirmed(true)

    for (let i = 0; i < fieldValidation.length; i++) {
      const key = fieldValidation[i];
      const value = templateLaunchParameters[key];
      const type = (typeof value);

      const min = templateLaunchhValidation[key + "Min"]
      const max = templateLaunchhValidation[key + "Max"]

      let msg;
      if (type === "string") {
        const pattern = templateLaunchhValidation[key + "Pattern"]
        msg = getFormFieldErrorText(value, min, max, pattern);
      } else if (type === "number") {
        msg = getFormFieldErrorNumber(value, min, max);
      } else {
        // console.log("no validation on key: " + key + " type: " + type);
      }

      if (msg !== undefined) {
        hasErrors = true;
      }
      errors[key] = (msg);
    }

    if (hasErrors) {
      setFormError(errors);
    } else {
      setFormError({});

      const [instance, error] = await launchTemplate(templateLaunchParameters);


      // setTemplateLaunchModalConfirmed(false)
      // setTemplateLaunchModalVisible(false);
      props.setIsVisible(false);

      let message: FlashbarProps.MessageDefinition;
      if (instance !== undefined)
        message = {
          type: "success",
          content: `Instance Id ${instance.instanceId} was launched succesfully.`,
          action: <Button onClick={() => navigate("/my-instances")} colorTheme="info" variation="primary">View instance</Button>,
          dismissible: true,
          dismissLabel: "Dismiss message",
          onDismiss: () => props.setFlashItems([]), id: "message_1"
        };
      else
        message = {
          type: "error",
          content: `There was a problemn launching the instance : ${error.message}`,
          dismissible: true,
          dismissLabel: "Dismiss message",
          onDismiss: () => props.setFlashItems([]), id: "message_2"
        };

      props.setFlashItems([
        message
      ])
    }
    setModalConfirmed(false)
  };

  return (
    <>
      <Modal onDismiss={() => onDismissModal()} visible={props.isVisible} size="large">
        {" "}
        <form>
          <Form
            actions={
              <Box float="right">
                <SpaceBetween direction="horizontal" size="xs">
                  <Button onClick={() => onDismissModal()} disabled={modalConfirmed} colorTheme="error" variation="link">
                    {I18n.get("Cancel")}
                  </Button>
                  <Button onClick={() => onConfirmModal()} disabled={modalConfirmed} colorTheme="success" variation="primary">
                    {I18n.get("Launch Instance")}
                  </Button>
                </SpaceBetween>
              </Box>
            }
          >
            <Container
              header={
                <Header variant="h2">
                  {" "}
                  Launch an instance from template :  {templateLaunchParameters.templateName}
                  {" "}
                </Header>
              }
            >
              <SpaceBetween size="m">
                <FormField label={I18n.get("Template Details")} stretch>
                  <Input
                    name="launchTemplateId"
                    value={"Id : " + templateLaunchParameters.launchTemplateId + " / Version : " + templateLaunchParameters.launchTemplateVersion}
                    type='text'
                    disabled={true}
                  />
                </FormField>
                <FormField label={I18n.get("Instance Name")} stretch errorText={formError['instanceName']}>
                  <Input
                    name="instanceName"
                    value={templateLaunchParameters.instanceName}
                    type='text'
                    disabled={modalConfirmed}
                    onChange={
                      (event) => {
                        const field = "instanceName"
                        onChangeFormInputHandle(field, event.target.value)
                      }
                    }
                    maxLength={64}
                    minLength={3}
                    pattern='a-zA-Z0-9_-'
                    style={{ width: "100%" }}
                  />
                </FormField>
                <FormField label={I18n.get("Instance Description")} stretch errorText={formError['instanceDescription']}>
                  <Textarea
                    onChange={
                      ({ detail: { value } }) => {
                        const field = "instanceDescription"
                        onChangeFormInputHandle(field, value)
                      }
                    }
                    value={templateLaunchParameters.instanceDescription}
                    name="instanceDescription"
                    disabled={modalConfirmed}
                  />
                </FormField>
                <FormField label={I18n.get("Instance Type")} stretch errorText={formError['instanceType']}>
                  <Select
                    selectedOption={{ label: templateLaunchParameters.instanceType, value: templateLaunchParameters.instanceType }}
                    disabled={modalConfirmed || instanceTypeListSelect.length <= 1}
                    onChange={
                      ({ detail: { selectedOption } }) => {
                        const field = "instanceType"
                        onChangeFormInputHandle(field, selectedOption.value)
                      }
                    }
                    options={instanceTypeListSelect}
                  >
                  </Select>
                </FormField>
                <FormField label={I18n.get("Volume Type")} stretch>
                  <Input
                    name="volumetype"
                    value={templateLaunchParameters.volumeType}
                    type='text'
                    disabled={true}
                  />
                </FormField>
                <FormField label={I18n.get("Volume Size")} stretch errorText={formError['volumeSize']}>
                  <Grid gridDefinition={[{ colspan: 10 }, { colspan: 2 }]}    >
                    <div>
                      <Slider
                        value={templateLaunchParameters.volumeSize}
                        onChange={
                          (event: Event, newValue: number | number[]) => {
                            const field = "volumeSize"; event.target;
                            onChangeFormInputHandle(field, newValue);
                          }
                        }
                        disabled={modalConfirmed || props.template.volumeSizeMin === props.template.volumeSizeMax}
                        aria-labelledby="input-slider"
                        marks={[
                          {
                            value: props.template.volumeSizeMin,
                            label: props.template.volumeSizeMin,
                          },
                          {
                            value: props.template.volumeSizeMax,
                            label: props.template.volumeSizeMax,
                          },
                        ]}
                        step={10}
                        valueLabelDisplay="auto"
                        min={props.template.volumeSizeMin}
                        max={props.template.volumeSizeMax}
                      />
                    </div>
                    <div>
                      <Input
                        name="volumeSize"
                        value={templateLaunchParameters.volumeSize}
                        type='text'
                        disabled={true}
                        size="small"
                      />
                    </div>
                  </Grid>
                </FormField>
                <FormField label={I18n.get("Volume IOPS")} stretch errorText={formError['volumeIops']}>
                  <Grid gridDefinition={[{ colspan: 10 }, { colspan: 2 }]}    >
                    <div>
                      <Slider
                        value={templateLaunchParameters.volumeIops}
                        onChange={
                          (event: Event, newValue: number | number[]) => {
                            const field = "volumeIops"; event.target;
                            onChangeFormInputHandle(field, newValue);
                          }
                        }
                        aria-labelledby="input-slider"
                        disabled={modalConfirmed || props.template.volumeIopsMin === props.template.volumeIopsMax}
                        marks={[
                          {
                            value: props.template.volumeIopsMin,
                            label: props.template.volumeIopsMin,
                          },
                          {
                            value: props.template.volumeIopsMax,
                            label: props.template.volumeIopsMax,
                          },
                        ]}
                        step={10}
                        valueLabelDisplay="auto"
                        min={props.template.volumeIopsMin}
                        max={props.template.volumeIopsMax}
                      />
                    </div>
                    <div>
                      <Input
                        name="volumeIops"
                        value={templateLaunchParameters.volumeIops}
                        type='text'
                        disabled={true}
                        size="small"
                      />
                    </div>
                  </Grid>
                </FormField>
                <FormField label={I18n.get("Volume Throughput")} stretch errorText={formError['volumeThroughput']}>
                  <Grid gridDefinition={[{ colspan: 10 }, { colspan: 2 }]}    >
                    <div>
                      <Slider
                        value={templateLaunchParameters.volumeThroughput}
                        onChange={
                          (event: Event, newValue: number | number[]) => {
                            const field = "volumeThroughput"; event.target;
                            onChangeFormInputHandle(field, newValue);
                          }
                        }
                        aria-labelledby="input-slider"
                        disabled={modalConfirmed || props.template.volumeThroughputMin === props.template.volumeThroughputMax}
                        marks={[
                          {
                            value: props.template.volumeThroughputMin,
                            label: props.template.volumeThroughputMin,
                          },
                          {
                            value: props.template.volumeThroughputMax,
                            label: props.template.volumeThroughputMax,
                          },
                        ]}
                        step={10}
                        valueLabelDisplay="auto"
                        min={props.template.volumeThroughputMin}
                        max={props.template.volumeThroughputMax}
                      />
                    </div>
                    <div>
                      <Input
                        name="volumeThroughput"
                        value={templateLaunchParameters.volumeThroughput}
                        type='text'
                        disabled={true}
                        size="small"
                      />
                    </div>
                  </Grid>
                </FormField>
              </SpaceBetween>
            </Container>
          </Form>
        </form>
      </Modal>
    </>
  );
};
export default TemplateLaunchModal;
