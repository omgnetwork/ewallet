import React from 'react';
import { storiesOf } from '@storybook/react';
import { withInfo } from '@storybook/addon-info';
import Alerter from '../../src/components/Alerter';

const containerStyle = {
  display: 'block',
  width: '600px',
  paddingLeft: '2rem',
};

const container = story => (
  <div style={containerStyle}>
    {story()}
  </div>
);

storiesOf('Alerter', module)
  .addDecorator(container)
  .add('alerter with danger props', (
    withInfo(`
        A component that is used to display API response for the user.
    `)
  )(() => {
    const alert = {
      type: 'alert-danger',
      message: 'OmiseGO Error',
    };
    return (
      <div>
        <Alerter alert={alert} />
      </div>
    );
  }));

storiesOf('Alerter', module)
  .addDecorator(container)
  .add('alerter with success props',  (
    withInfo(`
        A component that is used to display API response for the user.
    `)
  )(() => {
    const alert = {
      type: 'alert-success',
      message: 'OmiseGO Success',
    };
    return (
      <div>
        <Alerter alert={alert} />
      </div>
    );
  }));
