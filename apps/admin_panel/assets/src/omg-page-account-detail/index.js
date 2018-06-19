import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter } from 'react-router-dom'
import AccountProvider from '../omg-account/accountProvider'
import { Table, RatioBar } from '../omg-uikit'
import { compose } from 'recompose'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import moment from 'moment'
const AccountDetailContainer = styled.div`
  padding: 20px 0;
`
const ContentDetailContainer = styled.div`
  margin-top: 50px;
  display: flex;
`
const DetailContainer = styled.div`
  flex: 1 1 auto;
  :first-child {
    margin-right: 20px;
  }
`
const ContentContainer = styled.div`
  display: inline-block;
  width: 100%;
`

const enhance = compose(withTheme, withRouter)
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
          <b>Created:</b> {moment(account.created_at).format('DD/MM/YYYY hh:mm:ss')}
        </DetailGroup>
        <DetailGroup>
          <b>ID:</b> {account.id}
        </DetailGroup>
        <DetailGroup>
          <b>Description:</b> <span>{account.description}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Category:</b> <span>{_.get(account.categories, 'data[0].name')}</span>
        </DetailGroup>
        {/* <DetailGroup>
          <b>Category:</b> <span>{account.description}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Coins:</b> <span>{account.description}</span>
        </DetailGroup> */}
      </Section>
    )
  }
  renderTransactionRatio = account => {
    return (
      <Section title='TRANSACTION INFORMATION'>
        <RatioBar
          dataSource={[
            { percent: 20, content: 'transaction', color: this.props.theme.colors.B100 },
            { percent: 30, content: 'transaction', color: this.props.theme.colors.S500 }
          ]}
        />
      </Section>
    )
  }
  renderHistory = account => {
    const column = [
      { key: 'date', title: 'DATE' },
      {
        key: 'admin',
        title: 'ADMIN'
      },
      {
        key: 'action',
        title: 'ACTION'
      }
    ]
    const data = [
      {
        date: 'a,b,c',
        admin: 'c',
        action: 'remove omg from omg'
      },
      {
        date: 'a,b,c',
        admin: 'c',
        action: 'remove omg from omg'
      },
      {
        date: 'a,b,c',
        admin: 'c',
        action: 'remove omg from omg'
      }
    ]
    return (
      <Section title='HISTORY'>
        <Table columns={column} rows={data} />
      </Section>
    )
  }
  renderAccountDetailContainer = account => {
    const accountId = this.props.match.params.accountId
    return (
      <DetailLayout backPath={`/${accountId}/accounts`}>
        <ContentContainer>
          {this.renderTopBar(account)}
          <ContentDetailContainer>
            <DetailContainer>{this.renderDetail(account)}</DetailContainer>
            {/* <DetailContainer>
              {this.renderTransactionRatio(account)}
              {this.renderHistory(account)}
            </DetailContainer> */}
          </ContentDetailContainer>
        </ContentContainer>
      </DetailLayout>
    )
  }

  renderAccountDetailPage = ({ account, loadingStatus }) => {
    return (
      <AccountDetailContainer>
        {loadingStatus === 'SUCCESS' ? this.renderAccountDetailContainer(account) : 'loading'}
      </AccountDetailContainer>
    )
  }
  render () {
    return (
      <AccountProvider
        render={this.renderAccountDetailPage}
        accountId={this.props.match.params.viewAccountId}
      />
    )
  }
}

export default enhance(AccountDetailPage)
