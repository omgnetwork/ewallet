import uuid from 'uuid/v4'
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

export function getBlockchainWalletPlasmaBalance ({ address, perPage, page, sort, matchAny, matchAll }) {
  return authenticatedRequest({
    path: '/blockchain_wallet.get_balances',
    data: {
      blockchain_identifier: 'omg_network',
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

export function plasmaDeposit ({ address, amount, tokenId }) {
  return authenticatedRequest({
    path: '/blockchain_wallet.deposit_to_childchain',
    data: {
      address,
      amount,
      token_id: tokenId,
      idempotency_token: uuid()
    }
  })
}
