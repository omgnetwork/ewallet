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
  const onClickRow = (data, index) => e => {
    props.history.push(
      `/accounts/${props.match.params.accountId}/wallets/${data.address}`
    )
  }
  return (
    <WalletsPage
      transferButton
      onClickRow={onClickRow}
      walletQuery={{
        matchAny: getQuery()
      }}
    />
  )
}

AccountWalletSubPage.propTypes = {
  location: PropTypes.object,
  match: PropTypes.object,
  onClickRow: PropTypes.func
}

export default withRouter(AccountWalletSubPage)
