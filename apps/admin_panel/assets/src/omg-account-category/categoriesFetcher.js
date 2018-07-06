import { createFetcher } from '../utils/createFetcher'
import { getCategories } from './action'
import { selectCategories } from './selector'
export default createFetcher('categories', getCategories, (state, props) => ({
  data: selectCategories({ state, search: props.search })
}))
