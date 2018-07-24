import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import {
  getConsumptionById,
  getConsumptions,
  approveConsumptionById,
  rejectConsumptionById
} from './action'
import * as consumptionService from '../services/consumptionService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/consumptionService')
let store
describe('consumptions actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })
  test('[getConsumptionById] should dispatch success action if success to create transaction request', () => {
    consumptionService.getConsumptionById.mockImplementation(() => {
      return Promise.resolve({ data: { data: { id: 'a' }, success: true } })
    })
    const expectedActions = [
      { type: 'CONSUMPTION/REQUEST/INITIATED' },
      { type: 'CONSUMPTION/REQUEST/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(getConsumptionById('id')).then(() => {
      expect(consumptionService.getConsumptionById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
  test('[approveConsumptionById] should dispatch success action if success to create transaction request', () => {
    consumptionService.approveConsumptionById.mockImplementation(() => {
      return Promise.resolve({ data: { data: { id: 'a' }, success: true } })
    })
    const expectedActions = [
      { type: 'CONSUMPTION/APPROVE/INITIATED' },
      { type: 'CONSUMPTION/APPROVE/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(approveConsumptionById('id')).then(() => {
      expect(consumptionService.approveConsumptionById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
  test('[rejectConsumptionById] should dispatch success action if success to create transaction request', () => {
    consumptionService.rejectConsumptionById.mockImplementation(() => {
      return Promise.resolve({ data: { data: { id: 'a' }, success: true } })
    })
    const expectedActions = [
      { type: 'CONSUMPTION/REJECT/INITIATED' },
      { type: 'CONSUMPTION/REJECT/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(rejectConsumptionById('id')).then(() => {
      expect(consumptionService.rejectConsumptionById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
  test('[getConsumptions] should dispatch success action if get transaction requests successfully', () => {
    consumptionService.getConsumptions.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'CONSUMPTIONS/REQUEST/INITIATED' },
      {
        type: 'CONSUMPTIONS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store.dispatch(getConsumptions({ page: 1, perPage: 10, cacheKey: 'key' })).then(() => {
      expect(consumptionService.getConsumptions).toBeCalledWith(
        expect.objectContaining({
          page: 1,
          perPage: 10,
          sort: { by: 'created_at', dir: 'desc' }
        })
      )
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
})
