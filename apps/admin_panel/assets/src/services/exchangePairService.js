import { authenticatedRequest } from './apiService'

export function getExchangePairs ({ perPage, sort, search, searchTerms }) {
  return authenticatedRequest({
    path: '/exchange_pair.all',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      search_terms: searchTerms
    }
  })
}

export function getExchangePairById (id) {
  return authenticatedRequest({
    path: '/exchange_pair.get',
    data: {
      id
    }
  })
}
export function updateExchangePair ({ id, name, rate }) {
  return authenticatedRequest({
    path: '/exchange_pair.update',
    data: {
      id,
      name,
      rate
    }
  })
}
export function deleteExchangePairById (id) {
  return authenticatedRequest({
    path: '/exchange_pair.update',
    data: {
      id
    }
  })
}

export function createExchangePair ({ name, fromTokenId, toTokenId, rate, syncOpposite }) {
  return authenticatedRequest({
    path: '/exchange_pair.create',
    data: {
      name,
      from_token_id: fromTokenId,
      to_token_id: toTokenId,
      rate,
      sync_opposite: syncOpposite
    }
  })
}
