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
      this.props.history.push(`/accounts/${this.props.match.params.accountId}/users/${data.id}`)
    }

    render () {
      return (
        <AdminPage
          fetcher={adminsAccountFetcher}
          accountId={this.props.match.params.accountId}
          navigation={false}
          onClickRow={this.onClickRow}
        />
      )
    }
  }
)
