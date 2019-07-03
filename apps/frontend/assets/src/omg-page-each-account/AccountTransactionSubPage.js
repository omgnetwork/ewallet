import React from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import TransactionsPage from '../omg-page-transaction'

function AccountTransactionSubPage (props) {
  return (
    <TransactionsPage
      showFilter={false}
      transferButton
      divider={false}
      query={{
        matchAny: [
          {
            field: 'from_account.id',
            comparator: 'eq',
            value: props.match.params.accountId
          },
          {
            field: 'to_account.id',
            comparator: 'eq',
            value: props.match.params.accountId
          }
        ]
      }}
    />
  )
}

AccountTransactionSubPage.propTypes = {
  match: PropTypes.object
}

export default withRouter(AccountTransactionSubPage)
