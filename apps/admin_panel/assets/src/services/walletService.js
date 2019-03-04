import { authenticatedRequest } from './apiService'

export function getWallets ({ perPage, page, sort, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/wallet.all',
    data: {
      page,
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function getWalletsAndUserWalletsByAccountId ({
  accountId,
  perPage,
  page,
  sort,
  owned,
  matchAll,
  matchAny
}) {
  return authenticatedRequest({
    path: '/account.get_wallets_and_user_wallets',
    data: {
      page: page || 1,
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      id: accountId,
      owned,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function getWalletsByAccountId ({ accountId, perPage, sort, owned, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/account.get_wallets',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      id: accountId,
      owned,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function getWalletsByUserId ({ userId, perPage, page, sort, search, searchTerms }) {
  return authenticatedRequest({
    path: '/user.get_wallets',
    data: {
      page,
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      search_terms: searchTerms,
      id: userId
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
