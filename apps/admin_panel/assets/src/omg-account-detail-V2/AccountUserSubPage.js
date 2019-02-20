import AccountLayout from './AccountLayout'
import UserPage from '../omg-page-users'
import React from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import { getUsersByAccountId } from '../omg-users/usersFetcher'

function AccountTransactionSubPage (props) {
  return (
    <AccountLayout>
      <UserPage fetcher={getUsersByAccountId} accountId={props.match.params.accountId} />
    </AccountLayout>
  )
}

AccountTransactionSubPage.propTypes = {
  match: PropTypes.object
}

export default withRouter(AccountTransactionSubPage)
