import * as consumptionService from '../services/consumptionService'
import { selectGetConsumptionById } from '../omg-consumption/selector'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const getConsumptions = ({
  page,
  perPage,
  search,
  cacheKey,
  searchTerms,
  matchAll,
  matchAny
}) =>
  createPaginationActionCreator({
    actionName: 'CONSUMPTIONS',
    action: 'REQUEST',
    service: () =>
      consumptionService.getConsumptions({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search,
        searchTerms,
        matchAll,
        matchAny
      }),
    cacheKey
  })

export const getConsumptionById = id =>
  createActionCreator({
    actionName: 'CONSUMPTION',
    action: 'REQUEST',
    service: () => consumptionService.getConsumptionById(id)
  })

export const approveConsumptionById = id => async (dispatch, getState) => {
  dispatch({ type: 'CONSUMPTION/APPROVE/INITIATED' })
  try {
    const result = await consumptionService.approveConsumptionById(id)
    if (result.data.success) {
      return dispatch({
        type: 'CONSUMPTION/APPROVE/SUCCESS',
        data: result.data.data
      })
    } else {
      return dispatch({
        type: 'CONSUMPTION/APPROVE/FAILED',
        error: result.data.data,
        data: selectGetConsumptionById(getState())(id)
      })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'CONSUMPTION/APPROVE/FAILED', error })
  }
}

export const rejectConsumptionById = id => async dispatch => {
  dispatch({ type: 'CONSUMPTION/REJECT/INITIATED' })
  try {
    const result = await consumptionService.rejectConsumptionById(id)
    if (result.data.success) {
      return dispatch({
        type: 'CONSUMPTION/REJECT/SUCCESS',
        data: result.data.data
      })
    } else {
      return dispatch({ type: 'CONSUMPTION/REJECT/FAILED', error: result.data.data })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'CONSUMPTION/REJECT/FAILED', error })
  }
}
