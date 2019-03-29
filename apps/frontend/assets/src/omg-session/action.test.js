import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { login, logout, sendResetPasswordEmail, updatePasswordWithResetToken, updatePassword } from './action'
import * as sessionService from '../services/sessionService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/sessionService')
let store
describe('transaction actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })
  test('[login] should dispatch correct action if successfully login', () => {
    sessionService.login.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [{ type: 'SESSION/LOGIN/INITIATED' }, { type: 'SESSION/LOGIN/SUCCESS', data: { id: 'a' } }]
    return store
      .dispatch(
        login({
          email: 'email',
          password: 'password'
        })
      )
      .then(() => {
        expect(sessionService.login).toBeCalledWith({
          email: 'email',
          password: 'password'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
  test('[login] should dispatch correct action if unsuccessfully login', () => {
    sessionService.login.mockImplementation(() => {
      return Promise.resolve({ data: { success: false, data: { id: 'a' } } })
    })
    const expectedActions = [{ type: 'SESSION/LOGIN/INITIATED' }, { type: 'SESSION/LOGIN/FAILED', error: { id: 'a' } }]
    return store
      .dispatch(
        login({
          email: 'email',
          password: 'password'
        })
      )
      .then(() => {
        expect(sessionService.login).toBeCalledWith({
          email: 'email',
          password: 'password'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
  test('[logout] should dispatch correct action if successfully login', () => {
    sessionService.logout.mockImplementation(() => {
      return Promise.resolve({ data: { success: true } })
    })
    const expectedActions = [{ type: 'SESSION/LOGOUT/INITIATED' }, { type: 'SESSION/LOGOUT/SUCCESS' }]
    return store.dispatch(logout()).then(() => {
      expect(sessionService.logout).toBeCalled()
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[sendResetPasswordEmail] should dispatch correct action if successfully login', () => {
    sessionService.resetPassword.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: 'wow' } })
    })
    const expectedActions = [{ type: 'PASSWORD/RESET/INITIATED' }, { type: 'PASSWORD/RESET/SUCCESS', data: 'wow' }]
    return store.dispatch(sendResetPasswordEmail({ email: 'email', redirectUrl: 'omgone.com' })).then(() => {
      expect(sessionService.resetPassword).toBeCalledWith({
        email: 'email',
        redirectUrl: 'omgone.com?token={token}&email={email}'
      })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[updatePasswordWithResetToken] should dispatch correct action if successfully login', () => {
    sessionService.updatePasswordWithResetToken.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: 'wow' } })
    })
    const expectedActions = [
      { type: 'PASSWORD_TOKEN/UPDATE/INITIATED' },
      { type: 'PASSWORD_TOKEN/UPDATE/SUCCESS', data: 'wow' }
    ]
    return store
      .dispatch(
        updatePasswordWithResetToken({
          resetToken: 'token',
          password: 'pw',
          passwordConfirmation: 'pw',
          email: 'email@mail.com'
        })
      )
      .then(() => {
        expect(sessionService.updatePasswordWithResetToken).toBeCalledWith({
          resetToken: 'token',
          password: 'pw',
          passwordConfirmation: 'pw',
          email: 'email@mail.com'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
  test('[updatePasswordWithResetToken] should dispatch correct action if successfully login', () => {
    sessionService.updatePassword.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: 'wow' } })
    })
    const expectedActions = [{ type: 'PASSWORD/UPDATE/INITIATED' }, { type: 'PASSWORD/UPDATE/SUCCESS', data: 'wow' }]
    return store
      .dispatch(
        updatePassword({
          oldPassword: 'token',
          password: 'pw',
          passwordConfirmation: 'pw'
        })
      )
      .then(() => {
        expect(sessionService.updatePassword).toBeCalledWith({
          oldPassword: 'token',
          password: 'pw',
          passwordConfirmation: 'pw'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
})
