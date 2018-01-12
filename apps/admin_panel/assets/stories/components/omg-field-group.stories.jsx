import React from 'react';
import { storiesOf } from '@storybook/react';
import OMGFieldGroup from '../../src/components/OMGFieldGroup';

const container = {
  width: '300px',
  paddingLeft: '2rem',
};

const smallContainer = story => (
  <div style={container}>
    {story()}
  </div>
);

storiesOf('OMGFieldGroup', module)
  .addDecorator(smallContainer)
  .add('with error', () => (
    <OMGFieldGroup
      help="Email is invalid"
      id="email"
      label="Email"
      onChange={() => {}}
      type="text"
      validationState="error"
      value="john.doe"
    />
  ))
  .add('with warning', () => (
    <OMGFieldGroup help="" id="email" label="Email" type="text" validationState="warning" />
  ))
  .add('with success', () => (
    <OMGFieldGroup
      help=""
      id="email"
      label="Email"
      onChange={() => {}}
      type="text"
      validationState="success"
      value="john.doe@omise.co"
    />
  ));
