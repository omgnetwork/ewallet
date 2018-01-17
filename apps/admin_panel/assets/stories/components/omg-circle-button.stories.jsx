import React from 'react';
import { storiesOf } from '@storybook/react';
import OMGCircleButton from '../../src/components/OMGCircleButton';

const container = {
  width: '300px',
  paddingLeft: '2rem',
};

const smallContainer = story => (
  <div style={container}>
    {story()}
  </div>
);

storiesOf('OMGCircleButton', module)
  .addDecorator(smallContainer)
  .add('normal state', () => (
    <OMGCircleButton />
  ));
