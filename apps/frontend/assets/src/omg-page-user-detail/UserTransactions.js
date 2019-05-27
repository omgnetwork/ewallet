import TransactionsTable from '../omg-page-transaction/TransactionTable'
import { UserTransactionFetcher } from '../omg-transaction/transactionsFetcher'
import React from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import queryString from 'query-string'
function AccountTransactionSubPage (props) {
  const { page, search } = queryString.parse(props.location.search)
  return (
    <UserTransactionFetcher
      userId={props.match.params.userId}
      query={{
        page,
        perPage: 15,
        search
      }}
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
  match: PropTypes.object,
  location: PropTypes.object
}

export default withRouter(AccountTransactionSubPage)
