import React from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import TransactionRequestPage from '../omg-page-transaction-request'

function AccountTransactionRequestSubPage (props) {
  return (
    <TransactionRequestPage
      showFilter={false}
      createTransactionRequestButton
      divider={false}
      query={{
        matchAny: [
          {
            field: 'account.id',
            comparator: 'eq',
            value: props.match.params.accountId
          },
          {
            field: 'account.id',
            comparator: 'eq',
            value: null
          }
        ]
      }}
    />
  )
}

AccountTransactionRequestSubPage.propTypes = {
  match: PropTypes.object
}

export default withRouter(AccountTransactionRequestSubPage)
