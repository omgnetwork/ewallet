import TransactionsPage from '../omg-page-transaction'
import React from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'

function AccountTransactionSubPage (props) {
  return (
    <TransactionsPage
      transferButton
      divider={false}
      topNavigation={false}
      query={{
        matchAny: [
          {
            field: 'from_user.id',
            comparator: 'eq',
            value: props.match.params.userId
          },
          {
            field: 'to_user.id',
            comparator: 'eq',
            value: props.match.params.userId
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
