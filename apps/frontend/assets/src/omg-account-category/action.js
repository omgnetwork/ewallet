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

export const getCategories = ({ search, page, perPage }) => async dispatch => {
  try {
    const result = await categoryService.getCategories({
      perPage,
      page,
      search,
      sort: { by: 'created_at', dir: 'desc' }
    })
    if (result.data.success) {
      return dispatch({
        type: 'CATEGORIES/REQUEST/SUCCESS',
        data: result.data.data.data,
        pagination: result.data.data.pagination
      })
    } else {
      return dispatch({ type: 'CATEGORIES/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'CATEGORIES/REQUEST/FAILED', error })
  }
}
