import React from 'react';
import { storiesOf } from '@storybook/react';
import OMGSelectBox from '../../src/components/OMGSelectBox';

const containerStyle = {
  width: '300px',
  paddingLeft: '2rem',
  paddingTop: '2rem',
};

const container = story => (
  <div style={containerStyle}>
    {story()}
  </div>
);

storiesOf('OMGSelectBox', module)
  .addDecorator(container)
  .add('Empty options', () => <OMGSelectBox label="Select box" onOptionChanged={() => {}} />)
  .add('With default options 2', () => (
    <OMGSelectBox
      defaultValue="Option 2"
      label="Select box"
      onOptionChanged={() => {}}
      options={['Option 1', 'Option 2', 'Option 3']}
    />
  ));
