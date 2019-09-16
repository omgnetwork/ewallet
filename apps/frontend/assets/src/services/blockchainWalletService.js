import { authenticatedRequest } from './apiService'

export function getBlockchainWalletBalance ({ address, perPage, page, sort, matchAny, matchAll }) {
  return authenticatedRequest({
    path: '/blockchain_wallet.get_balances',
    data: {
      address,
      page,
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function getBlockchainWallet (address) {
  return authenticatedRequest({
    path: '/blockchain_wallet.get',
    data: { address }
  })
}

export function getAllBlockchainWallets ({ perPage, sort, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/blockchain_wallet.all',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function createBlockchainWallet ({ name, type, address }) {
  return authenticatedRequest({
    path: '/blockchain_wallet.create',
    data: {
      name,
      type,
      address
    }
  })
}
