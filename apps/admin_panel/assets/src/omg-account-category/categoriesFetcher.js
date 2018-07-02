import { createFetcher } from '../utils/createFetcher'
import { getCategories } from './action'
import { selectCategories } from './selector'
export default createFetcher(getCategories, (state, props) => ({
  cachedCategories: selectCategories({ state, search: props.search })
}))
