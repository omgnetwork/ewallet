import { authenticatedRequest } from './apiService'

export function getAllTokens ({ per, sort, query, ...rest }) {
  return authenticatedRequest({
    path: '/token.all',
    data: {
      per_page: per,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: query,
      ...rest
    }
  })
}

export function createToken ({ name, symbol, decimal = 18, amount = 0 }) {
  return authenticatedRequest({
    path: '/token.create',
    data: {
      name,
      symbol,
      subunit_to_unit: parseInt(Math.pow(10, decimal)),
      amount
    }
  })
}

export function mintToken ({ id, amount }) {
  return authenticatedRequest({
    path: '/token.mint',
    data: { id, amount: Number(amount) }
  })
}
