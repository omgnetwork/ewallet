import React from 'react';
import { render } from 'react-dom';
import { Provider } from 'react-redux';

import App from './pages/App';
import store from './store/store';

import './styles/styles.scss';

render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById('app'), // eslint-disable-line no-undef
);
