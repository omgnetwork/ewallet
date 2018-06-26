import { createFetcher } from '../utils/createFetcher'
import { getUsers } from './action'
export default createFetcher(getUsers)
