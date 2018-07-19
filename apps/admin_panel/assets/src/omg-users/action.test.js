import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { getUserById, getUsers, createUser } from './action'
import * as userService from '../services/userService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/userService')
let store
describe('users actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })

  test('[getUserById] should dispatch success action if get user successfully', () => {
    userService.getUserById.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'USER/REQUEST/INITIATED' },
      { type: 'USER/REQUEST/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(getUserById('id')).then(() => {
      expect(userService.getUserById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[createUser] should dispatch success action if create user successfully', () => {
    userService.createUser.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'USER/CREATE/INITIATED' },
      { type: 'USER/CREATE/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(createUser({ username: 'name' })).then(() => {
      expect(userService.createUser).toBeCalledWith({
        username: 'name',
        providerUserId: undefined
      })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
  test('[getUsers] should dispatch success action if get users successfully', () => {
    userService.getUsers.mockImplementation(() => {
      return Promise.resolve({
        data: { success: true, data: { data: 'data', pagination: 'pagination' } }
      })
    })
    const expectedActions = [
      { type: 'USERS/REQUEST/INITIATED' },
      {
        type: 'USERS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store
      .dispatch(getUsers({ accountId: '1', page: 1, perPage: 10, cacheKey: 'key' }))
      .then(() => {
        expect(userService.getUsers).toBeCalledWith(
          expect.objectContaining({ accountId: '1', page: 1, perPage: 10 })
        )
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
})
