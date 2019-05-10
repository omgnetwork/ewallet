import { createFetcher } from '../utils/createFetcher'
import { getMintedTokenHistory } from './action'
import { selectMintedTokenHistoryCachedQuery } from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher('tokensHistory', getMintedTokenHistory, (state, props) => ({
  data: selectMintedTokenHistoryCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey)
}))
