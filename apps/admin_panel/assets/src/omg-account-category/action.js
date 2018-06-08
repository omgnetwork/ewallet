import * as categoryService from '../services/categoryService'
export const createCategory = ({ name, description, accountId }) => async dispatch => {
  try {
    const result = await categoryService.createCategory({
      name, description, accountId
    })
    if (result.data.success) {
      return dispatch({ type: 'CATEGORY/CREATE/SUCCESS', category: result.data.data })
    } else {
      return dispatch({ type: 'CATEGORY/CREATE/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'CATEGORY/CREATE/FAILED', error })
  }
}
