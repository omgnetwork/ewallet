import React, { Component, Fragment } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter, Link } from 'react-router-dom'
import { compose } from 'recompose'
import moment from 'moment'
import queryString from 'query-string'
import { connect } from 'react-redux'

import TokensFetcher from '../omg-token/tokensFetcher'
import TokenProvider from '../omg-token/TokenProvider'
import ExchangePairsProvider from '../omg-exchange-pair/exchangePairProvider'
import { Button, Breadcrumb, Id } from '../omg-uikit'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import MintTokenModal from '../omg-mint-token-modal'
import ExchangeRateModal from '../omg-exchange-rate-modal'
import HistoryTable from './HistoryTable'
import { formatReceiveAmountToTotal, formatNumber } from '../utils/formatter'
import { getMintedTokenHistory } from '../omg-token/action'
import { createCacheKey } from '../utils/createFetcher'

const TokenDetailContainer = styled.div`
  padding-bottom: 20px;
`
const ContentDetailContainer = styled.div`
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

const ActionButtons = styled.div`
  float: right;
  display: flex;
  flex-direction: row;

  .button {
    cursor: pointer;
    color: ${props => props.theme.colors.BL300};
    padding-left: 20px;
  }
`

const BreadcrumbContainer = styled.div`
  margin-top: 30px;
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
    mintTokenModalOpen: false,
    exchangeRateModalOpen: false,
    deleteExchangeRateModalOpen: false,
    exchangeRateToEdit: null,
    exchangeRateToDelete: null
  }
  onRequestClose = () => {
    this.setState({
      mintTokenModalOpen: false,
      exchangeRateModalOpen: false,
      deleteExchangeRateModalOpen: false,
      exchangeRateToEdit: null,
      exchangeRateToDelete: null
    })
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
  editExchangePair = (pair) => {
    this.setState({
      exchangeRateModalOpen: true,
      exchangeRateToEdit: pair
    })
  }
  deleteExchangePair = (pair) => {
    this.setState({
      deleteExchangeRateModalOpen: true,
      exchangeRateToDelete: pair
    })
  }

  renderCreateExchangePairButton = () => {
    return (
      <TokensFetcher
        key='create-exchange-pair-button'
        render={({ data: tokens }) => {
          if (tokens.length > 1) {
            return (
              <Button
                key='rate'
                size='small'
                styleType='secondary'
                onClick={this.onClickCreateExchangeRate}
              >
                <span>Create Exchange Pair</span>
              </Button>
            )
          }
          return null
        }}
      />
    )
  }

  renderTopBar = token => {
    return (
      <>
        <BreadcrumbContainer>
          <Breadcrumb
            items={[
              <Link key='token' to={'/tokens/'}>Token</Link>,
              token.name
            ]}
          />
        </BreadcrumbContainer>
        <TopBar
          title={token.name}
          buttons={[
            this.renderCreateExchangePairButton(),
            <Button
              key='mint'
              size='small'
              onClick={this.onClickMintTopen}
            >
              <span>Mint Token</span>
            </Button>
          ]}
        />
      </>
    )
  }
  renderDetail = token => {
    return (
      <Section title={{ text: 'Details', icon: 'Option-Horizontal' }}>
        <DetailGroup>
          <b>ID:</b><Id>{token.id}</Id>
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
          <span style={{ marginRight: '10px' }}>
            {token.total_supply === undefined
              ? '...'
              : formatReceiveAmountToTotal(token.total_supply, token.subunit_to_unit)}{' '}
            {token.symbol}
          </span>
          <Link to={`${this.props.location.pathname}/history`}>view history</Link>
        </DetailGroup>
        <DetailGroup>
          <b>Created At:</b> <span>{moment(token.created_at).format()}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Updated At:</b> <span>{moment(token.updated_at).format()}</span>
        </DetailGroup>
      </Section>
    )
  }

  renderTokenDetail = () => {
    return (
      <TokenProvider
        tokenId={this.props.match.params.viewTokenId}
        render={({ token }) => {
          return token ? (
            <div>
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
                action='create'
                onRequestClose={this.onRequestClose}
                open={this.state.exchangeRateModalOpen}
                fromTokenId={token.id}
                toEdit={this.state.exchangeRateToEdit}
              />
              <ExchangeRateModal
                action='delete'
                open={this.state.deleteExchangeRateModalOpen}
                onRequestClose={this.onRequestClose}
                toDelete={this.state.exchangeRateToDelete}
              />
            </div>
          ) : null
        }}
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
              <Section title={{ text: 'Rates', icon: 'Token' }}>
                <DetailGroup>
                  <h5>1 {token.name} :</h5>
                  {exchangePairs.map(pair => {
                    return (
                      <DetailGroup key={pair.id}>
                        <b>{_.get(pair, 'to_token.name')}</b>
                        <span>
                          {_.round(pair.rate, 3)} {_.get(pair, 'to_token.symbol')}
                        </span>
                        <ActionButtons>
                          <div className='button' onClick={() => this.editExchangePair(pair)}>
                            Edit
                          </div>
                          <div className='button' onClick={() => this.deleteExchangePair(pair)}>
                            Delete
                          </div>
                        </ActionButtons>
                      </DetailGroup>
                    )
                  })}
                </DetailGroup>
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
