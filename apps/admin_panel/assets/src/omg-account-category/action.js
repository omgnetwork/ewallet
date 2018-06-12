import * as categoryService from '../services/categoryService'
export const createCategory = ({ name, description, accountId }) => async dispatch => {
  try {
    const result = await categoryService.createCategory({
      name,
      description,
      accountId
    })
    if (result.data.success) {
      dispatch({ type: 'CATEGORY/CREATE/SUCCESS', category: result.data.data })
    } else {
      dispatch({ type: 'CATEGORY/CREATE/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    return dispatch({ type: 'CATEGORY/CREATE/FAILED', error })
  }
}

export const getCategories = search => async dispatch => {
  try {
    const result = await categoryService.getCategories({
      per: 1000,
      sort: { by: 'created_at', dir: 'desc' }
    })
    if (result.data.success) {
      return dispatch({ type: 'CATEGORIES/REQUEST/SUCCESS', categories: result.data.data })
    } else {
      return dispatch({ type: 'CATEGORIES/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'CATEGORIES/REQUEST/FAILED', error })
  }
}
