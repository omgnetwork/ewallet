import React from 'react';
import { storiesOf } from '@storybook/react';
import { Provider } from 'react-redux';
import { BrowserRouter as Router } from 'react-router-dom';
import store from '../../../../src/store/store';
import SignIn from '../../../../src/pages/public/signin/SignIn';

const reduxDecorator = story => (
  <Router>
    <Provider store={store}>
      {story()}
    </Provider>
  </Router>
);

storiesOf('SignIn', module)
  .addDecorator(reduxDecorator)
  .add('init', () => <SignIn />);
