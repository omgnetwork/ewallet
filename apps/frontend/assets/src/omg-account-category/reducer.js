import createReducer from '../reducer/createReducer'

export const categoriesReducer = createReducer(
  {},
  {
    'CATEGORIES/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'CATEGORY/CREATE/SUCCESS': (state, action) => {
      return { ...state, [action.category.id]: action.category }
    }
  }
)

export const categoriesLoadingStatusReducer = createReducer('DEFAULT', {
  'CATEGORIES/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'CATEGORIES/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CATEGORIES/REQUEST/FAILED': (state, action) => 'FAILED'
})
