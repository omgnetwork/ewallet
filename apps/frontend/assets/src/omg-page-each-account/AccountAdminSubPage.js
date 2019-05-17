import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { withRouter } from 'react-router-dom'

import MembersPage from '../omg-page-members'
import MembersFetcher from '../omg-member/MembersFetcher'

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
        <MembersPage
          divider={false}
          fetcher={MembersFetcher}
          accountId={this.props.match.params.accountId}
          navigation={false}
          onClickRow={this.onClickRow}
          showInviteButton
        />
      )
    }
  }
)
