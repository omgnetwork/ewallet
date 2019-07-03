import React from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'

import UserPage from '../omg-page-users'
import { getUsersByAccountId } from '../omg-users/usersFetcher'

function AccountTransactionSubPage (props) {
  const onClickRow = (data, index) => e => {
    props.history.push(`/accounts/${props.match.params.accountId}/users/${data.id}`)
  }
  return (
    <UserPage
      showFilter={false}
      fetcher={getUsersByAccountId}
      accountId={props.match.params.accountId}
      onClickRow={onClickRow}
      divider={false}
    />
  )
}

AccountTransactionSubPage.propTypes = {
  match: PropTypes.object,
  history: PropTypes.object
}

export default withRouter(AccountTransactionSubPage)
