import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter } from 'react-router-dom'
import TokenProvider from '../omg-token/TokenProvider'
import { compose } from 'recompose'
import { Button } from '../omg-uikit'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import moment from 'moment'
import MintTokenModal from '../omg-mint-token-modal'
import ExchangeRateModal from '../omg-exchange-rate-modal'
import { formatNumber } from '../utils/formatter'
const AccountDetailContainer = styled.div`
  padding-bottom: 20px;
  padding-top: 3px;
`
const ContentDetailContainer = styled.div`
  margin-top: 40px;
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

const enhance = compose(
  withTheme,
  withRouter
)
class TokenDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    theme: PropTypes.object
  }
  state = {
    mintTokenModalOpen: false
  }
  onRequestClose = () => {
    this.setState({ mintTokenModalOpen: false, exchangeRateModalOpen: false })
  }
  onClickMintTopen = e => {
    this.setState({ mintTokenModalOpen: true })
  }
  onClickCreateExchangeRate = e => {
    this.setState({ exchangeRateModalOpen: true })
  }
  renderTopBar = token => {
    return (
      <TopBar
        title={token.name}
        breadcrumbItems={['Token', `${token.name} (${token.symbol})`]}
        buttons={[
          <Button size='small' styleType='secondary' onClick={this.onClickCreateExchangeRate} key='rate'>
            <span>Create Rate</span>
          </Button>,
          <Button size='small' onClick={this.onClickMintTopen} key='mint'>
            <span>Mint Token</span>
          </Button>

        ]}
      />
    )
  }
  renderDetail = token => {
    return (
      <Section title='DETAILS'>
        <DetailGroup>
          <b>Symbol:</b> <span>{token.symbol}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Decimal:</b> <span>{Math.log10(token.subunit_to_unit)}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Subunit To Unit:</b> <span>{formatNumber(token.subunit_to_unit)}</span>
        </DetailGroup>
        <DetailGroup>
          <b>ID:</b> <span>{token.id}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Created date:</b> <span>{moment(token.created_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Last update:</b> <span>{moment(token.updated_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
      </Section>
    )
  }
  renderAccountDetailContainer = token => {
    const accountId = this.props.match.params.accountId
    return (
      <DetailLayout backPath={`/${accountId}/token`}>
        <ContentContainer>
          {this.renderTopBar(token)}
          <ContentDetailContainer>
            <DetailContainer>{this.renderDetail(token)}</DetailContainer>
          </ContentDetailContainer>
        </ContentContainer>
        <MintTokenModal
          token={token}
          onRequestClose={this.onRequestClose}
          open={this.state.mintTokenModalOpen}
        />
        <ExchangeRateModal
          onRequestClose={this.onRequestClose}
          open={this.state.exchangeRateModalOpen}
        />
      </DetailLayout>
    )
  }

  renderTokenDetailPage = ({ token, loadingStatus }) => {
    return (
      <AccountDetailContainer>
        {token && this.renderAccountDetailContainer(token)}
      </AccountDetailContainer>
    )
  }
  render () {
    return (
      <TokenProvider
        render={this.renderTokenDetailPage}
        tokenId={this.props.match.params.viewTokenId}
        {...this.state}
      />
    )
  }
}

export default enhance(TokenDetailPage)
