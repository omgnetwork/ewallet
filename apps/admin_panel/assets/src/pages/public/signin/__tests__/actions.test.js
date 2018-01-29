import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import Cookies from 'js-cookie';
import Actions from '../actions';
import globalConstants from '../../../../constants/global.constants';
import sessionConstants from '../../../../constants/session.constants';
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

describe('login action', () => {
  test('shows and hide loading when requesting', () => {
    sessionAPI.login = jest.fn((params, cb) => cb(null, validResponse));
    const store = mockStore();
    const expectedActions = [
      { type: globalConstants.SHOW_LOADING },
      { type: globalConstants.HIDE_LOADING },
    ];
    store.dispatch(Actions.login(validParams));
    expect(store.getActions()).toEqual(expect.arrayContaining(expectedActions));
  });

  test('saves session cookie, push to /accounts and set synced to false', () => {
    sessionAPI.login = jest.fn((params, cb) => cb(null, validResponse));
    const store = mockStore();
    const expectedActions = [{
      payload: {
        args: ['/accounts'],
        method: 'push',
      },
      type: '@@router/CALL_HISTORY_METHOD',
    },
    { type: sessionConstants.SET_SYNCED, sync: false },
    ];
    store.dispatch(Actions.login(validParams));
    expect(Cookies.get(sessionConstants.SESSION_COOKIE)).toBe('a_valid_user_id:a_valid_token');
    expect(store.getActions()).toEqual(expect.arrayContaining(expectedActions));
  });

  test('calls handleAPIError when failing', () => {
    sessionAPI.login = jest.fn((params, cb) => cb(errorResponse, null));
    mockStore().dispatch(Actions.login(validParams));
    expect(ErrorHandler.handleAPIError).toBeCalledWith(expect.any(Function), errorResponse);
  });
});
