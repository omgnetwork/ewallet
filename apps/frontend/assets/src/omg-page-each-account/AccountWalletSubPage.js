import React from 'react'
import queryString from 'query-string'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'

import WalletsPage from '../omg-page-wallets'
import walletFetcher from '../omg-wallet/accountUsersWalletsFetcher'

function AccountWalletSubPage (props) {
  const { walletType } = queryString.parse(props.location.search)
  function getQuery () {
    const userWalletQuery = [
      {
        field: 'account.id',
        comparator: 'eq',
        value: null
      }
    ]
    const accountWalletQuery = [
      {
        field: 'account.id',
        comparator: 'eq',
        value: props.match.params.accountId
      }
    ]

    switch (walletType) {
      case 'user':
        return userWalletQuery
      case 'account':
        return accountWalletQuery
      default:
        return accountWalletQuery
    }
  }
  const onClickRow = (data, index) => e => {
    props.history.push(`/accounts/${props.match.params.accountId}/wallets/${data.address}`)
  }
  return (
    <WalletsPage
      showFilter={false}
      transferButton
      accountId={props.match.params.accountId}
      fetcher={walletFetcher}
      onClickRow={onClickRow}
      walletQuery={{
        matchAll: getQuery()
      }}
      divider={false}
      title={walletType === 'user' ? 'User Wallets' : 'Account Wallets'}
    />
  )
}

AccountWalletSubPage.propTypes = {
  location: PropTypes.object,
  match: PropTypes.object,
  history: PropTypes.object
}

export default withRouter(AccountWalletSubPage)
