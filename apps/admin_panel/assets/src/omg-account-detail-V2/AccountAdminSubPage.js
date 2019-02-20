import React, { Component } from 'react'
import PropTypes from 'prop-types'
import AdminPage from '../omg-page-admins'
import adminsAccountFetcher from '../omg-member/MembersFetcher'
import { withRouter } from 'react-router-dom'
export default withRouter(
  class AccountAdminSubPage extends Component {
    static propTypes = {
      match: PropTypes.object
    }

    render () {
      return (
        <AdminPage
          fetcher={adminsAccountFetcher}
          accountId={this.props.match.params.accountId}
          navigation={false}
        />
      )
    }
  }
)
