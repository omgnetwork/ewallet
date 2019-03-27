import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter } from 'react-router-dom'
import AccountProvider from '../omg-account/accountProvider'
import { compose } from 'recompose'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopNavigation from '../omg-page-layout/TopNavigation'
import moment from 'moment'
import Copy from '../omg-copy'

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
        <TopNavigation title={'Details'} divider={false} secondaryAction={false}/>
        <Section>
          <DetailGroup>
            <b>ID:</b> {account.id} <Copy data={account.id} />
          </DetailGroup>
          <DetailGroup>
            <b>Description:</b> {account.description || '-'}
          </DetailGroup>
          <DetailGroup>
            <b>Category:</b> {_.get(account.categories, 'data[0].name', '-')}
          </DetailGroup>
          <DetailGroup>
            <b>Created Date:</b> {moment(account.created_at).format()}
          </DetailGroup>
          <DetailGroup>
            <b>Last Update:</b> {moment(account.updated_at).format()}
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
