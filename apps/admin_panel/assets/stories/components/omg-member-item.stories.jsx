import React from 'react';
import { storiesOf } from '@storybook/react';
import { Provider } from 'react-redux';
import { BrowserRouter as Router } from 'react-router-dom';
import store from '../../src/store/store';
import OMGMemberItem from '../../src/components/OMGMemberItem';

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

const reduxDecorator = story => (
  <Router>
    <Provider store={store}>
      {story()}
    </Provider>
  </Router>
);

storiesOf('OMGMemberItem', module)
  .addDecorator(container)
  .addDecorator(reduxDecorator)
  .add('normal', () => (
    <div>
      <OMGMemberItem
        imageUrl="https://6f553f294d9c2b381dc8-21a51a0c688da9b8f39d1cd2f922214e.ssl.cf3.rackcdn.com/photos/131-3-4.jpg"
        name="Thibault Denizut"
        position="OmiseGO Software Developer Team Lead"
      />
      <OMGMemberItem
        imageUrl="https://6f553f294d9c2b381dc8-21a51a0c688da9b8f39d1cd2f922214e.ssl.cf3.rackcdn.com/photos/146-0-4.jpg"
        name="Phuchit Sirimongkolsathien"
        position="OmiseGO Mobile App Developer"
      />
      <OMGMemberItem
        imageUrl="https://6f553f294d9c2b381dc8-21a51a0c688da9b8f39d1cd2f922214e.ssl.cf3.rackcdn.com/photos/139-0-4.jpg"
        name="Mederic Petit"
        position="OmiseGO Mobile App Developer"
      />
    </div>
  ));
