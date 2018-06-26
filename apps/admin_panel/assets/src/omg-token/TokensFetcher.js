import { createFetcher } from '../utils/createFetcher'
import { getTokens } from './action'
import { selectTokensLoadingStatus } from './selector'
export default createFetcher(getTokens, (state, props) => ({
  loadingStatus: selectTokensLoadingStatus(state)
}))
