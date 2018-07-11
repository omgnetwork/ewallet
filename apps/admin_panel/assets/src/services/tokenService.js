import { authenticatedRequest } from './apiService'

export function getAllTokens ({ page, perPage, sort, search, searchTerms }) {
  return authenticatedRequest({
    path: '/token.all',
    data: {
      page,
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      search_terms: searchTerms
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
export function getTokenStatsById (id) {
  return authenticatedRequest({
    path: '/token.stats',
    data: { id }
  })
}

export function getMintedTokenHistory ({ tokenId, page, perPage, search, searchTerms, sort }) {
  return authenticatedRequest({
    path: '/token.get_mints',
    data: {
      page,
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      id: tokenId
    }
  })
}

export function getTokenById (id) {
  return authenticatedRequest({
    path: '/token.get',
    data: { id }
  })
}
