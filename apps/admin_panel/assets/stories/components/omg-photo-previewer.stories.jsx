import React from 'react';
import { storiesOf } from '@storybook/react';
import OMGPhotoPreviewer from '../../src/components/OMGPhotoPreviewer';
import User from '../../public/images/user_icon_placeholder.png';

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

storiesOf('OMGPhotoPreviewer', module)
  .addDecorator(container)
  .add('normal', () => <OMGPhotoPreviewer onFileChanged={() => {}} />)
  .add('hide upload button', () => (
    <OMGPhotoPreviewer onFileChanged={() => {}} showUploadBtn={false} />
  ))
  .add('show close button', () => (
    <OMGPhotoPreviewer onFileChanged={() => {}} showCloseBtn showUploadBtn={false} />
  ))
  .add('with different placeholder', () => (
    <OMGPhotoPreviewer img={User} onFileChanged={() => {}} showUploadBtn={false} />
  ));
