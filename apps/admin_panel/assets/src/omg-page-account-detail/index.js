import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter } from 'react-router-dom'
import AccountProvider from '../omg-account/accountProvider'
import { compose } from 'recompose'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import moment from 'moment'
import Copy from '../omg-copy'
const AccountDetailContainer = styled.div``
const ContentDetailContainer = styled.div`
  margin-top: 20px;
  display: flex;
  > div {
    flex: 1 1 50%;
  }
`
const ContentContainer = styled.div`
  display: inline-block;
  width: 100%;
`
const enhance = compose(
  withTheme,
  withRouter
)
class AccountDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    theme: PropTypes.object
  }
  renderTopBar = account => {
    return <TopBar title={account.name} breadcrumbItems={['Account', account.name]} />
  }
  renderDetail = account => {
    return (
      <Section title='DETAILS'>
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
    )
  }
  renderAccountDetailContainer = account => {
    return (
      <ContentContainer>
        <ContentDetailContainer>{this.renderDetail(account)}</ContentDetailContainer>
      </ContentContainer>
    )
  }

  renderAccountDetailPage = ({ account, loadingStatus }) => {
    return (
      <AccountDetailContainer>
        {account && this.renderAccountDetailContainer(account)}
      </AccountDetailContainer>
    )
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
