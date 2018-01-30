import React from 'react';
import { Provider } from 'react-redux';
import { getTranslate } from 'react-localize-redux';
import { createMemoryHistory } from 'history';
import PropTypes from 'prop-types';
import { shallow, mount } from 'enzyme';
import { MemoryRouter } from 'react-router-dom';
import store from './testStore';

// To test snapshots
export const SnapshotComponentTester = (Component, props) => {
  SnapshotComponentTester.propTypes = {
    component: PropTypes.func.isRequired,
  };

  return (
    <MemoryRouter>
      <Provider store={store}>
        <Component.WrappedComponent
          history={createMemoryHistory()}
          translate={getTranslate(store.getState().locale)}
          {...props}
        />
      </Provider>
    </MemoryRouter>
  );
};

// To test business logic only
export const ShallowComponentTester = (Component, props) => {
  ShallowComponentTester.propTypes = {
    component: PropTypes.func.isRequired,
  };

  return shallow(<Provider store={store}>
    <Component.WrappedComponent
      history={createMemoryHistory()}
      translate={getTranslate(store.getState().locale)}
      {...props}
    />
  </Provider>).dive(); //eslint-disable-line
};

// To test full logic including react component callbacks
export const MountedComponentTester = (Component, props) => {
  MountedComponentTester.propTypes = {
    component: PropTypes.func.isRequired,
  };
  return mount(<Provider store={store}>
    <Component.WrappedComponent
      history={createMemoryHistory()}
      translate={getTranslate(store.getState().locale)}
      {...props}
    />
  </Provider>) //eslint-disable-line
};
