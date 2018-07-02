export const selectCategories = ({ state, search }) =>
  _.values(state.categories).filter(cat => new RegExp(search).test(cat.name))
export const selectCategoriesLoadingStatus = state => state.categoriesLoadingStatus
