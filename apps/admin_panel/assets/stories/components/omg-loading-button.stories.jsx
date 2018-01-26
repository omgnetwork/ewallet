import React from 'react';
import { storiesOf } from '@storybook/react';
import { Provider } from 'react-redux';
import { BrowserRouter as Router } from 'react-router-dom';
import OMGLoadingButton from '../../src/components/OMGLoadingButton';
import store from '../../src/store/store';

const container = {
  width: '300px',
  paddingLeft: '2rem',
  paddingTop: '2rem',
};

const reduxDecorator = story => (
  <Router>
    <Provider store={store}>
      {story()}
    </Provider>
  </Router>
);

const smallContainer = story => (
  <div style={container}>
    {story()}
  </div>
);

storiesOf('OMGLoadingButton', module)
  .addDecorator(smallContainer)
  .addDecorator(reduxDecorator)
  .add('normal state', () => (
    <OMGLoadingButton>
      Save
    </OMGLoadingButton>
  ))
  .add('loading state', () => (
    <OMGLoadingButton loading />
  ))
  .add('white button', () => (
    <OMGLoadingButton className="btn-omg-white">
      Save
    </OMGLoadingButton>
  ))
  .add('white button with loading', () => (
    <OMGLoadingButton className="btn-omg-white" loading />
  ))
  .add('red button', () => (
    <OMGLoadingButton className="btn-omg-red">
      Save
    </OMGLoadingButton>
  ))
  .add('red button with loading', () => (
    <OMGLoadingButton className="btn-omg-red" loading />
  ));
