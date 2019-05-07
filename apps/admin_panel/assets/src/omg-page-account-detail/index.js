import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { withTheme } from 'styled-components'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'
import moment from 'moment'

import AccountProvider from '../omg-account/accountProvider'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Id } from '../omg-uikit'

const enhance = compose(
  withTheme,
  withRouter
)
class AccountDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object
  }

  renderAccountDetailContainer = account => {
    return (
      <>
        <TopNavigation title={'Details'} divider={false} searchBar={false} />
        <Section>
          <DetailGroup>
            <b>ID:</b><Id>{account.id}</Id>
          </DetailGroup>
          <DetailGroup>
            <b>Description:</b> {account.description || '-'}
          </DetailGroup>
          <DetailGroup>
            <b>Category:</b> {_.get(account.categories, 'data[0].name', '-')}
          </DetailGroup>
          <DetailGroup>
            <b>Created At:</b> {moment(account.created_at).format()}
          </DetailGroup>
          <DetailGroup>
            <b>Updated At:</b> {moment(account.updated_at).format()}
          </DetailGroup>
        </Section>
      </>
    )
  }

  renderAccountDetailPage = ({ account }) => {
    return account && this.renderAccountDetailContainer(account)
  }

  render () {
    return (
      <AccountProvider
        {...this.props}
        render={this.renderAccountDetailPage}
        accountId={this.props.match.params.accountId}
      />
    )
  }
}

export default enhance(AccountDetailPage)
