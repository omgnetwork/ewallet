import React from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import queryString from 'query-string'

import TransactionsTable from '../omg-page-transaction/TransactionTable'
import TransactionFetcher from '../omg-transaction/transactionsFetcher'

function WalletTransactions ({ match, location }) {
  const { page } = queryString.parse(location.search)
  const address = match.params.walletAddress
  return (
    <TransactionFetcher
      query={{
        page,
        perPage: 10,
        matchAny: [
          {
            field: 'from_wallet.address',
            comparator: 'contains',
            value: address
          },
          {
            field: 'to_wallet.address',
            comparator: 'contains',
            value: address
          }
        ]
      }}
      render={({ data: transactions, individualLoadingStatus, pagination }) => {
        return (
          <TransactionsTable
            loadingStatus={individualLoadingStatus}
            pagination={pagination}
            transactions={transactions}
          />
        )
      }}
    />
  )
}

WalletTransactions.propTypes = {
  match: PropTypes.object,
  location: PropTypes.object
}

export default withRouter(WalletTransactions)
