import { authenticatedRequest } from './apiService'

export function getWallets ({ perPage, sort, query, ...rest }) {
  return authenticatedRequest({
    path: '/wallet.all',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: query,
      ...rest
    }
  })
}

export function getWalletsByAccountId ({ accountId, perPage, sort, search, ...rest }) {
  return authenticatedRequest({
    path: '/account.get_wallets',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      id: accountId,
      ...rest
    }
  })
}

export function getWalletsByUserId ({ userId, perPage, sort, query, ...rest }) {
  return authenticatedRequest({
    path: '/user.get_wallets',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: query,
      id: userId,
      ...rest
    }
  })
}

export function getWallet (address) {
  return authenticatedRequest({
    path: '/wallet.get',
    data: {
      address
    }
  })
}

