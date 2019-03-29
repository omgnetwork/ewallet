import React, { Component } from 'react'
import PropTypes from 'prop-types'
import AdminPage from '../omg-page-admins'
import adminsAccountFetcher from '../omg-member/MembersFetcher'
import { withRouter } from 'react-router-dom'
export default withRouter(
  class AccountAdminSubPage extends Component {
    static propTypes = {
      match: PropTypes.object,
      history: PropTypes.object
    }
    onClickRow = (data, index) => e => {
      this.props.history.push(`/accounts/${this.props.match.params.accountId}/admins/${data.id}`)
    }

    render () {
      return (
        <AdminPage
          divider={false}
          fetcher={adminsAccountFetcher}
          accountId={this.props.match.params.accountId}
          navigation={false}
          onClickRow={this.onClickRow}
          columns={[
            { key: 'id', title: 'ADMIN ID', sort: true },
            { key: 'email', title: 'EMAIL', sort: true },
            { key: 'account_role', title: 'ROLE', sort: true },
            { key: 'status', title: 'STATUS', sort: true }
          ]}
        />
      )
    }
  }
)
