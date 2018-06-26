import { createFetcher } from '../utils/createFetcher'
import { getTransactions } from './action'
export default createFetcher(getTransactions)
