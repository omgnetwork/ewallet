import AccountLayout from './AccountLayout'
import WalletsPage from '../omg-page-wallets'
import React from 'react'
import queryString from 'query-string'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'

function AccountWalletSubPage (props) {
  function getQuery () {
    const { walletType } = queryString.parse(props.location.search)
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
    const allWalletQuery = [...userWalletQuery, ...accountWalletQuery]

    switch (walletType) {
      case 'all':
        return allWalletQuery
      case 'user':
        return userWalletQuery
      case 'account':
        return accountWalletQuery
      default:
        return allWalletQuery
    }
  }
  return (
    <WalletsPage
      transferButton
      walletQuery={{
        matchAny: getQuery()
      }}
    />
  )
}

AccountWalletSubPage.propTypes = {
  location: PropTypes.object,
  match: PropTypes.object
}

export default withRouter(AccountWalletSubPage)
