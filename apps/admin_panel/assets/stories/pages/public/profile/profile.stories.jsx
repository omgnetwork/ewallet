import React from 'react';
import { storiesOf } from '@storybook/react';
import { BrowserRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import store from '../../../../src/store/store';
import Profile from '../../../../src/pages/authenticated/profile/Profile';

const reduxDecorator = story => (
  <Router>
    <Provider store={store}>
      {story()}
    </Provider>
  </Router>
);

const containerStyle = {
  width: '1200px',
  paddingLeft: '2rem',
  paddingTop: '2rem',
  paddingBottom: '2rem',
};

const container = story => (
  <div style={containerStyle}>
    {story()}
  </div>
);

const currentUser = {
  username: 'satoshi',
  email: 'satoshi@omise.co',
  fullName: 'Satoshi Kojiro',
  position: 'Software Developer',
  companyName: 'OmiseGO',
  photoUrl: 'https://omisego.network/assets/images/icon-blockchain.svg',
};

storiesOf('Profile', module)
  .addDecorator(reduxDecorator)
  .addDecorator(container)
  .add('normal state', () => <Profile />)
  .add('with some user info', () => <Profile currentUser={currentUser} />);
