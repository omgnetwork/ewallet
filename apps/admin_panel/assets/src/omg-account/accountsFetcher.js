import { createFetcher } from '../utils/createFetcher'
import { getAccounts } from './action'
export default createFetcher(getAccounts)
