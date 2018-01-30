import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import Actions from '../actions';
import globalConstants from '../../../../constants/global.constants';
import { validResponse, errorResponse, validParams } from './stubs';

const mockStore = configureMockStore([thunk]);

// Require for test specific function mock override
const sessionAPI = require('../../../../omisego/services/session_api');
// Require for global function mock override
const ErrorHandler = require.requireMock('../../../../helpers/errorHandler');
// global function mock override of `handleAPIError`
jest.mock('../../../../helpers/errorHandler', () => (
  { handleAPIError: jest.fn() }
));

describe('forgotPassword action', () => {
  test('shows and hide loading when requesting', () => {
    const callback = jest.fn();
    sessionAPI.forgotPassword = jest.fn((params, cb) => cb(null, validResponse));
    const store = mockStore();
    const expectedActions = [
      { type: globalConstants.SHOW_LOADING },
      { type: globalConstants.HIDE_LOADING },
    ];
    store.dispatch(Actions.forgotPassword(validParams, callback));
    expect(store.getActions()).toEqual(expect.arrayContaining(expectedActions));
  });

  test('call onSuccess when success', () => {
    const callback = jest.fn();
    sessionAPI.forgotPassword = jest.fn((params, cb) => cb(null, validResponse));
    const store = mockStore();
    store.dispatch(Actions.forgotPassword(validParams, callback));
    expect(callback).toBeCalled();
  });

  test('calls handleAPIError when failing', () => {
    const callback = jest.fn();
    sessionAPI.forgotPassword = jest.fn((params, cb) => cb(errorResponse, null));
    mockStore().dispatch(Actions.forgotPassword(validParams, callback));
    expect(ErrorHandler.handleAPIError).toBeCalledWith(expect.any(Function), errorResponse);
  });
});
