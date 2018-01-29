import React from 'react';
import { Provider } from 'react-redux';
import { getTranslate } from 'react-localize-redux';
import { createBrowserHistory } from 'history';
import PropTypes from 'prop-types';
import { shallow, mount } from 'enzyme';
import store from './testStore';

// To test snapshots
export const SnapshotComponentTester = (Component, props) => {
  SnapshotComponentTester.propTypes = {
    component: PropTypes.func.isRequired,
  };

  return (
    <Provider store={store}>
      <Component.WrappedComponent
        history={createBrowserHistory()}
        translate={getTranslate(store.getState().locale)}
        {...props}
      />
    </Provider>
  );
};

// To test business logic only
export const ShallowComponentTester = (Component, props) => {
  ShallowComponentTester.propTypes = {
    component: PropTypes.func.isRequired,
  };

  return shallow(<Provider store={store}>
    <Component.WrappedComponent
      history={createBrowserHistory()}
      translate={getTranslate(store.getState().locale)}
      {...props}
    />
  </Provider>).dive(); //eslint-disable-line
};

// To test full logic including react compoenent callbacks
export const MountedComponentTester = (Component, props) => {
  MountedComponentTester.propTypes = {
    component: PropTypes.func.isRequired,
  };
  return mount(<Provider store={store}>
    <Component.WrappedComponent
      history={createBrowserHistory()}
      translate={getTranslate(store.getState().locale)}
      {...props}
    />
  </Provider>); //eslint-disable-line
};
