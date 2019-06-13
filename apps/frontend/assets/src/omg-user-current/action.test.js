import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'

import { getCurrentUser, updateCurrentUserEmail, updateCurrentUserAvatar } from './action'
import * as currentUserService from '../services/currentUserService'
import * as adminService from '../services/adminService'

const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)

jest.mock('../services/currentUserService')
jest.mock('../services/adminService')

let store
describe('current user actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })

  test('[getCurrentUser] should dispatch success action if get current user successfully', () => {
    currentUserService.getCurrentUser.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'CURRENT_USER/REQUEST/INITIATED' },
      { type: 'CURRENT_USER/REQUEST/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(getCurrentUser()).then(() => {
      expect(currentUserService.getCurrentUser).toBeCalled()
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[updateCurrentUserEmail] should dispatch success action if update current user email successfully', () => {
    currentUserService.updateCurrentUserEmail.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'CURRENT_USER_EMAIL/UPDATE/INITIATED' },
      { type: 'CURRENT_USER_EMAIL/UPDATE/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(updateCurrentUserEmail({ email: 'email' })).then(() => {
      expect(currentUserService.updateCurrentUserEmail).toBeCalledWith({ email: 'email' })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[updateCurrentUserAvatar] should dispatch success action if update current user avatar successfully', () => {
    adminService.uploadAvatar.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'CURRENT_USER/UPDATE/INITIATED' },
      { type: 'CURRENT_USER/UPDATE/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(updateCurrentUserAvatar({ avatar: 'path/to/avatar' })).then(() => {
      expect(adminService.uploadAvatar).toBeCalledWith({ avatar: 'path/to/avatar' })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
})
