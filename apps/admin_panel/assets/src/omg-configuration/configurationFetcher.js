import { createFetcher } from '../utils/createFetcher'
import { getConfiguration } from './action'
import { selectConfigurations } from './selector'
export default createFetcher('configurations', getConfiguration, (state, props) => ({
  data: selectConfigurations(state)
}))
