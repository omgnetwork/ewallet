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

export function getWalletsByAccountId ({ accountId, per, sort, query, ...rest }) {
  return authenticatedRequest({
    path: '/account.get_wallets',
    data: {
      per_page: per,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: query,
      ...rest,
      id: accountId
    }
  })
}

export function getWallet (id) {
  return authenticatedRequest({
    path: '/wallet.get',
    data: {
      address: id
    }
  })
}
