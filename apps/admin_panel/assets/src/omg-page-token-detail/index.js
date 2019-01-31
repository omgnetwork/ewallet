import React, { Component, Fragment } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter, Link } from 'react-router-dom'
import TokenProvider from '../omg-token/TokenProvider'
import ExchangePairsProvider from '../omg-exchange-pair/exchangePairProvider'
import { compose } from 'recompose'
import { Button } from '../omg-uikit'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import moment from 'moment'
import MintTokenModal from '../omg-mint-token-modal'
import ExchangeRateModal from '../omg-exchange-rate-modal'
import HistoryTable from './HistoryTable'
import { formatReceiveAmountToTotal, formatNumber } from '../utils/formatter'
import { getMintedTokenHistory } from '../omg-token/action'
import { createCacheKey } from '../utils/createFetcher'
import queryString from 'query-string'
import { connect } from 'react-redux'
import Copy from '../omg-copy'
const TokenDetailContainer = styled.div`
  padding-bottom: 20px;
`
const ContentDetailContainer = styled.div`
  margin-top: 40px;
  display: flex;
  width: 100%;
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
  withRouter,
  connect(
    null,
    { getMintedTokenHistory }
  )
)
class TokenDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    location: PropTypes.object,
    getMintedTokenHistory: PropTypes.func
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
  onMintTokenSuccess = () => {
    if (this.props.match.params.state === 'history') {
      const query = {
        page: queryString.parse(this.props.location.search).page,
        perPage: 10,
        search: queryString.parse(this.props.location.search).search,
        tokenId: this.props.match.params.viewTokenId
      }
      this.props.getMintedTokenHistory({
        ...query,
        cacheKey: createCacheKey({ query }, 'tokensHistory')
      })
    }
  }
  renderTopBar = token => {
    return (
      <TopBar
        title={token.name}
        breadcrumbItems={['Token', `${token.name} (${token.symbol})`]}
        buttons={[
          <Button
            size='small'
            styleType='secondary'
            onClick={this.onClickCreateExchangeRate}
            key='rate'
          >
            <span>Create Exchange Pair</span>
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
          <b>ID:</b> <span>{token.id}</span> <Copy data={token.id} />
        </DetailGroup>
        <DetailGroup>
          <b>Name:</b> <span>{token.name}</span>
        </DetailGroup>
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
          <b>Total Supply:</b>{' '}
          <span>
            {token.total_supply === undefined
              ? '...'
              : formatReceiveAmountToTotal(token.total_supply, token.subunit_to_unit)}{' '}
            {token.symbol}
          </span>{' '}
          <Link to={`${this.props.location.pathname}/history`}>view history</Link>
        </DetailGroup>
        <DetailGroup>
          <b>Created Date:</b> <span>{moment(token.created_at).format('DD/MM/YYYY HH:mm:ss')}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Last Update:</b> <span>{moment(token.updated_at).format('DD/MM/YYYY HH:mm:ss')}</span>
        </DetailGroup>
      </Section>
    )
  }

  renderTokenDetail = () => {
    return (
      <TokenProvider
        render={({ token }) => {
          return token ? (
            <DetailLayout>
              <ContentContainer>
                {this.renderTopBar(token)}
                <ContentDetailContainer>
                  {this.props.match.params.state !== 'history' && (
                    <Fragment>
                      <DetailContainer>{this.renderDetail(token)}</DetailContainer>
                      {this.renderExchangeRate(token)}
                    </Fragment>
                  )}
                  {this.props.match.params.state === 'history' && (
                    <HistoryTable tokenId={token.id} />
                  )}
                </ContentDetailContainer>
              </ContentContainer>

              <MintTokenModal
                token={token}
                onRequestClose={this.onRequestClose}
                open={this.state.mintTokenModalOpen}
                onSuccess={this.onMintTokenSuccess}
              />
              <ExchangeRateModal
                onRequestClose={this.onRequestClose}
                open={this.state.exchangeRateModalOpen}
                fromTokenId={token.id}
              />
            </DetailLayout>
          ) : null
        }}
        tokenId={this.props.match.params.viewTokenId}
      />
    )
  }
  renderExchangeRate = token => {
    return (
      <ExchangePairsProvider
        fromTokenId={this.props.match.params.viewTokenId}
        render={({ exchangePairs }) => {
          return exchangePairs.length ? (
            <DetailContainer>
              <Section title={'RATES'}>
                <h5>1 {token.name} :</h5>
                {exchangePairs.map(pair => {
                  return (
                    <DetailGroup key={pair.id}>
                      <b>{_.get(pair, 'to_token.name')}</b>
                      {pair.rate} {_.get(pair, 'to_token.symbol')}
                    </DetailGroup>
                  )
                })}
              </Section>
            </DetailContainer>
          ) : null
        }}
      />
    )
  }

  render () {
    return <TokenDetailContainer>{this.renderTokenDetail()}</TokenDetailContainer>
  }
}

export default enhance(TokenDetailPage)
