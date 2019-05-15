import * as exchangePairService from '../services/exchangePairService'

export const updateExchangePair = ({ id, rate, syncOpposite, defaultExchangeWalletAddress,
  allowEndUserExchanges }) => async dispatch => {
  try {
    const result = await exchangePairService.updateExchangePair({
      id,
      rate,
      syncOpposite,
      defaultExchangeWalletAddress,
      allowEndUserExchanges
    })
    if (result.data.success) {
      return dispatch({ type: 'EXCHANGE_PAIR/UPDATE/SUCCESS', data: result.data.data })
    } else {
      return dispatch({ type: 'EXCHANGE_PAIR/UPDATE/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'EXCHANGE_PAIR/UPDATE/FAILED', error })
  }
}

export const deleteExchangePair = ({ id }) => async dispatch => {
  try {
    const result = await exchangePairService.deleteExchangePairById({ id })
    if (result.data.success) {
      return dispatch({ type: 'EXCHANGE_PAIR/DELETE/SUCCESS', data: result.data.data })
    } else {
      return dispatch({ type: 'EXCHANGE_PAIR/DELETE/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'EXCHANGE_PAIR/DELETE/FAILED', error })
  }
}

export const createExchangePair = ({
  name,
  toTokenId,
  fromTokenId,
  rate,
  syncOpposite,
  defaultExchangeWalletAddress,
  allowEndUserExchanges
}) => async dispatch => {
  try {
    const result = await exchangePairService.createExchangePair({
      name,
      toTokenId,
      fromTokenId,
      rate,
      syncOpposite,
      defaultExchangeWalletAddress,
      allowEndUserExchanges
    })
    if (result.data.success) {
      return dispatch({ type: 'EXCHANGE_PAIR/CREATE/SUCCESS', data: result.data.data })
    } else {
      return dispatch({ type: 'EXCHANGE_PAIR/CREATE/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'EXCHANGE_PAIR/CREATE/FAILED', error })
  }
}

export const getExchangePairs = ({ search, page, perPage, searchTerms }) => async dispatch => {
  try {
    const result = await exchangePairService.getExchangePairs({
      perPage,
      page,
      search,
      searchTerms,
      sort: { by: 'created_at', dir: 'desc' }
    })
    if (result.data.success) {
      return dispatch({
        type: 'EXCHANGE_PAIRS/REQUEST/SUCCESS',
        data: result.data.data.data,
        pagination: result.data.data.pagination
      })
    } else {
      return dispatch({ type: 'EXCHANGE_PAIRS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'EXCHANGE_PAIRS/REQUEST/FAILED', error })
  }
}
