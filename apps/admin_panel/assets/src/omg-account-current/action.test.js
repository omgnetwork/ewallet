import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { updateCurrentAccount, getCurrentAccount } from './action'
import * as accountService from '../services/accountService'
jest.mock('../services/accountService')
let store
const joinChannel = jest.fn()
describe('account actions', () => {
  beforeEach(() => {
    const middlewares = [thunk.withExtraArgument({ socket: { joinChannel } })]
    const mockStore = configureMockStore(middlewares)
    jest.resetAllMocks()
    store = mockStore({ accounts: {} })
  })
  test('[updateAccount] should dispatch success action if can update current account', () => {
    accountService.updateAccountInfo.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'accc' } } })
    })
    accountService.uploadAccountAvatar.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'accc' } } })
    })
    const expectedActions = [
      { type: 'CURRENT_ACCOUNT/UPDATE/INITIATED' },
      { type: 'CURRENT_ACCOUNT/UPDATE/SUCCESS', data: { id: 'accc' } }
    ]
    return store
      .dispatch(
        updateCurrentAccount({
          accountId: 'accc',
          description: 'description',
          avatar: 'avatar',
          name: 'name'
        })
      )
      .then(() => {
        expect(accountService.updateAccountInfo).toBeCalledWith({
          name: 'name',
          description: 'description',
          id: 'accc'
        })
        expect(accountService.uploadAccountAvatar).toBeCalledWith({
          accountId: 'accc',
          avatar: 'avatar'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })

  test('[getCurrentAccount] should dispatch success action if can update current account', () => {
    accountService.getAccountById.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'accc' } } })
    })
    const expectedActions = [
      { type: 'CURRENT_ACCOUNT/REQUEST/INITIATED' },
      { type: 'CURRENT_ACCOUNT/REQUEST/SUCCESS', data: { id: 'accc' } }
    ]
    return store.dispatch(getCurrentAccount('accc')).then(() => {
      expect(accountService.getAccountById).toBeCalledWith('accc')
      expect(store.getActions()).toEqual(expectedActions)
      expect(joinChannel).toBeCalledWith('account:accc')
    })
  })
})
