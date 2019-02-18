import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { Link, withRouter } from 'react-router-dom'
import { Avatar } from '../omg-uikit'
import AccountProvider from '../omg-account/accountProvider'

class AccountNavigationBar extends Component {
  static propTypes = {
    prop: PropTypes
  }

  render () {
    return (
      <div>
        <div>
          <Avatar />
        </div>
        <div>
          <Link to={`/accounts/${this.props.match.params.accountId}/detail`}>Details</Link>
          <Link to={`/accounts/${this.props.match.params.accountId}/requests`}>Requests</Link>
          <Link to={`/accounts/${this.props.match.params.accountId}/transactions`}>
            Transactions
          </Link>
          <Link to={`/accounts/${this.props.match.params.accountId}/users`}>Users</Link>,
          <Link to={`/accounts/${this.props.match.params.accountId}/admins`}>Admins</Link>
          <Link to={`/accounts/${this.props.match.params.accountId}/setting`}>Setting</Link>
        </div>
      </div>
    )
  }
}

export default withRouter(AccountNavigationBar)
