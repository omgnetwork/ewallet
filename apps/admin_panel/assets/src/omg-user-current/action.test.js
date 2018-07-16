import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { getCurrentUser, updateCurrentUser } from './action'
import * as currentUserService from '../services/currentUserService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/currentUserService')
let store
describe('wallet actions', () => {
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
  test('[updateCurrentUser]  should dispatch success action if update current user successfully', () => {
    currentUserService.updateCurrentUser.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'CURRENT_USER/UPDATE/INITIATED' },
      { type: 'CURRENT_USER/UPDATE/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(updateCurrentUser({ email: 'email' })).then(() => {
      expect(currentUserService.updateCurrentUser).toBeCalledWith({ email: 'email' })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
})
