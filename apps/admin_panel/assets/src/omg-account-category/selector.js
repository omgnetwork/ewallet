import {fuzzySearch} from '../utils/search'
export const selectCategories = ({ state, search }) =>
  _.values(state.categories).filter(cat => fuzzySearch(search, cat.name))
export const selectCategoriesLoadingStatus = state => state.categoriesLoadingStatus
