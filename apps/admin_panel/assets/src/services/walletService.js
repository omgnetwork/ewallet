import { authenticatedRequest } from './apiService'

export function getWallets ({ per, sort, query, ...rest }) {
  return authenticatedRequest({
    path: '/wallet.all',
    data: {
      per_page: per,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: query,
      ...rest
    }
  })
}

export function getWallet (id) {
  return authenticatedRequest({
    path: '/wallet.all',
    data: {
      address: id
    }
  })
}
