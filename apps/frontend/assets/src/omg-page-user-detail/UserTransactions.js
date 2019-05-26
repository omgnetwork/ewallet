import TransactionsTable from '../omg-page-transaction/TransactionTable'
import { UserTransactionFetcher } from '../omg-transaction/transactionsFetcher'
import React from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
function AccountTransactionSubPage (props) {
  return (
    <UserTransactionFetcher
      userId={props.match.params.userId}
      render={({
        data: transactions,
        individualLoadingStatus,
        pagination,
        fetch
      }) => {
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

AccountTransactionSubPage.propTypes = {
  match: PropTypes.object
}

export default withRouter(AccountTransactionSubPage)
