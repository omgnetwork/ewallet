import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { getConfiguration, updateConfiguration } from './action'
import * as configurationService from '../services/configurationService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/configurationService.js')
let store
describe('configurations actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })

  test('[getConfiguration] should dispatch success action if get configuration successfully', () => {
    configurationService.getConfiguration.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'CONFIGURATIONS/REQUEST/INITIATED' },
      { type: 'CONFIGURATIONS/REQUEST/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(getConfiguration()).then(() => {
      expect(configurationService.getConfiguration).toBeCalled()
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
  test('[updateConfiguration]  should dispatch success action if update configuration successfully', () => {
    configurationService.updateConfiguration.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'CONFIGURATIONS/UPDATE/INITIATED' },
      { type: 'CONFIGURATIONS/UPDATE/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(updateConfiguration({ base_url: 'xxx@gmail.com' })).then(() => {
      expect(configurationService.updateConfiguration).toBeCalled()
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
})
