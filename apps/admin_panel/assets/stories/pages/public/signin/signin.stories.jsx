import React from 'react';
import { storiesOf } from '@storybook/react';
import { Provider } from 'react-redux';
import store from '../../../../src/store/store';
import SignIn from '../../../../src/pages/public/signin/SignIn';

const reduxDecorator = story => (
  <Provider store={store}>
    {story()}
  </Provider>
);

storiesOf('SignIn', module)
  .addDecorator(reduxDecorator)
  .add('init', () => <SignIn />);
