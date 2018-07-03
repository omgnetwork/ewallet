import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import TabPanel from './TabPanel'
import SortableTable from '../omg-table'
import ConsumptionFetcherByTransactionIdFetcher from '../omg-consumption/consumptionByTransactionIdFetcher'
import TransactionRequestProvider from '../omg-transaction-request/transactionRequestProvider'
import { Icon, Button, Select, Input } from '../omg-uikit'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
import QR from './QrCode'
import moment from 'moment'
import { connect } from 'react-redux'
import { approveConsumptionById, rejectConsumptionById } from '../omg-consumption/action'
import { compose } from 'recompose'
import { formatNumber } from '../utils/formatter'
import AllWalletsFetcher from '../omg-wallet/allWalletsFetcher'
import TokensFetcher from '../omg-token/tokensFetcher'
import { consumeTransactionRequest } from '../omg-transaction-request/action'
import { selectGetTransactionRequestById } from '../omg-transaction-request/selector'
const PanelContainer = styled.div`
  height: 100vh;
  position: fixed;
  right: 0;
  width: 550px;
  background-color: white;
  padding: 40px 30px;
  box-shadow: 0 0 15px 0 rgba(4, 7, 13, 0.1);
  > i {
    position: absolute;
    right: 0;
    color: ${props => props.theme.colors.S500};
    top: 0;
    cursor: pointer;
    padding: 20px;
  }
`
const ContentContainer = styled.div`
  height: calc(100vh - 160px);
  overflow: auto;
  table tr td {
    height: 22px;
    vertical-align: middle;
  }
  td:first-child {
    max-width: 100px;
    width: 100px;
    > div {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }
  td:nth-child(2) {
    max-width: 120px;
    width: 120px;
    > div {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }
`
const ConsumeActionContainer = styled.form`
  display: flex;
  margin: 20px 0;
  border: 1px solid ${props => props.theme.colors.S300};
  border-radius: 4px;
  background-color: ${props => props.theme.colors.S100};
  position: relative;
`
const TokenAmountContainer = styled.div`
  display: flex;
  > div:first-child {
    padding-right: 20px;
  }
`
const InformationItem = styled.div`
  color: ${props => props.theme.colors.B200};
  :not(:last-child) {
    margin-bottom: 10px;
  }
`
const QrContainer = styled.div`
  background-color: white;
  padding: 20px;
  > img {
    width: 100px;
    height: 100px;
    margin: -10px;
  }
  > div {
    color: ${props => props.theme.colors.B300};
  }
`
const InputsContainer = styled.div`
  flex: 1 1 auto;
  padding: 20px;
  text-align: right;
  > div:not(:last-child) {
    margin-bottom: 20px;
  }
`
const TransactionReqeustPropertiesContainer = styled.div`
  height: calc(100vh - 160px);
  overflow: auto;
  b {
    font-weight: 600;
    color: ${props => props.theme.colors.B200};
  }
`
const SubDetailTitle = styled.div`
  margin-top: 10px;
  color: ${props => props.theme.colors.B100};
  margin-bottom: 10px;
  > span {
    padding: 0 5px;
    :first-child {
      padding-left: 0;
    }
  }
`
const AdditionalRequestDataContainer = styled.div`
  > div {
    margin-bottom: 10px;
  }
  h5 {
    margin-bottom: 10px;
    letter-spacing: 1px;
  }
`
const ConfirmButton = styled.button`
  display: inline-block;
  background-color: white;
  cursor: pointer;
  border-radius: 2px;
  padding: 4px 10px;
  line-height: 10px;
  color: ${props => props.theme.colors.B200};
  i {
    font-size: 10px;
  }
`
const QrTypeContainer = styled.div`
  margin-top: 15px;
  :not(:last-child) {
    margin-bottom: 10px;
  }
  > div {
    color: ${props => props.theme.colors.B300};
  }
`
const ConfirmButtonApprove = ConfirmButton.extend`
  :hover {
    color: #16826b;
    background-color: #dcfaf4;
  }
`
const ConfirmButtonReject = ConfirmButton.extend`
  :hover {
    color: #d51404;
    background-color: #ffefed;
  }
`
const InputLabel = styled.div`
  margin-top: 20px;
  font-size: 14px;
  font-weight: 400;
  color: ${props => (props.disabled ? props.theme.colors.S400 : props.theme.colors.B300)};
`
const InputLabelContainer = styled.div`
  text-align: left;
`
const ExpiredContainer = styled.div`
  background-color: ${props => props.theme.colors.S200};
  color: ${props => props.theme.colors.S500};
  border-radius: 4px;
  padding: 5px 10px;
  margin-top: 32px;
  text-align: center;
`
const enhance = compose(
  withRouter,
  connect(
    state => ({
      selectTransactionRequestById: selectGetTransactionRequestById(state)
    }),
    { approveConsumptionById, rejectConsumptionById, consumeTransactionRequest }
  )
)
const Error = styled.div`
  color: ${props => props.theme.colors.R400};
  padding: ${props => (props.error ? '10px 0' : 0)};
  overflow: hidden;
  max-height: ${props => (props.error ? '50px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
  text-align: right;
`
class TransactionRequestPanel extends Component {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object,
    rejectConsumptionById: PropTypes.func,
    approveConsumptionById: PropTypes.func,
    consumeTransactionRequest: PropTypes.func,
    selectTransactionRequestById: PropTypes.func
  }

  static getDerivedStateFromProps (props, state) {
    const transactionRequestId = queryString.parse(props.location.search)['show-request-tab']
    const transactionRequest = props.selectTransactionRequestById(transactionRequestId)
    if (!_.isEmpty(transactionRequest) && state.transactionRequestId !== transactionRequestId) {
      return {
        transactionRequestId,
        amount: transactionRequest.amount / transactionRequest.token.subunit_to_unit,
        selectedToken: transactionRequest.token,
        searchTokenValue: `${transactionRequest.token.name} (${transactionRequest.token.symbol})`
      }
    }
    return null
  }

  constructor (props) {
    super(props)
    this.state = {}
    this.columns = [
      { key: 'amount', title: 'AMOUNT', sort: true },
      { key: 'to', title: 'TO' },
      { key: 'created_at', title: 'CREATED DATE', sort: true },
      { key: 'status', title: 'CONFIRMATION' }
    ]
  }
  onClickConfirm = id => async e => {
    e.stopPropagation()
    await this.props.approveConsumptionById(id)
  }
  onClickReject = id => e => {
    e.stopPropagation()
    this.props.rejectConsumptionById(id)
  }
  onChangeWalletInput = e => {
    this.setState({ consumeAddress: e.target.value })
  }
  onChangeAmount = e => {
    this.setState({ amount: e.target.value })
  }
  onSelectWalletAddressSelect = item => {
    this.setState({ consumeAddress: item.key })
  }
  onChangeSearchToken = e => {
    this.setState({ searchTokenValue: e.target.value, selectedToken: null })
  }
  onSelectTokenSelect = token => {
    this.setState({ searchTokenValue: token.value, selectedToken: token })
  }
  onClickRow = (data, index) => e => {
    const searchObject = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        [`show-consumption-tab`]: data.id
      })
    })
  }
  onClickClose = () => {
    const searchObject = queryString.parse(this.props.location.search)
    delete searchObject['active-tab']
    delete searchObject['show-request-tab']
    delete searchObject['page-activity']
    this.props.history.push({
      search: queryString.stringify(searchObject)
    })
  }
  onClickTab = tab => e => {
    const searchObject = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        [`active-tab`]: tab
      })
    })
  }
  onSubmitConsume = transactionRequest => async e => {
    e.preventDefault()
    this.setState({ submitStatus: 'SUBMITTING' })
    try {
      const result = await this.props.consumeTransactionRequest({
        formattedTransactionRequestId: transactionRequest.id,
        tokenId: this.state.selectedToken.id,
        amount: transactionRequest.allow_amount_override
          ? Number(this.state.amount) * _.get(this.state.selectedToken, 'subunit_to_unit')
          : null,
        address: this.state.consumeAddress
      })
      if (result.data) {
        this.setState({ submitStatus: 'SUCCESS', error: null })
      } else {
        this.setState({ submitStatus: 'FAILED', error: result.error.description })
      }
    } catch (error) {
      this.setState({ submitStatus: 'FAILED', error: `${error}` })
    }
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'amount') {
      return (
        <div>
          {formatNumber((data || 0) / _.get(rows, 'token.subunit_to_unit'))}{' '}
          {_.get(rows, 'token.symbol')}
        </div>
      )
    }
    if (key === 'created_at') {
      return moment(data).format('DD/MM hh:mm:ss')
    }
    if (key === 'to') {
      return <div>{rows.user_id || _.get(rows, 'account.name')}</div>
    }

    if (key === 'status') {
      switch (data) {
        case 'pending':
          return (
            <div>
              <ConfirmButtonApprove onClick={this.onClickConfirm(rows.id)}>
                <Icon name='Checked' />
              </ConfirmButtonApprove>
              <ConfirmButtonReject onClick={this.onClickReject(rows.id)}>
                <Icon name='Close' />
              </ConfirmButtonReject>
            </div>
          )
        case 'confirmed': {
          return 'Confirmed'
        }
        case 'failed': {
          return 'Failed'
        }
        case 'rejected': {
          return 'Rejected'
        }
        default:
          return <span>{data}</span>
      }
    }
    return data
  }
  getExpiredReason = reason => {
    switch (reason) {
      case 'max_consumptions_reached':
        return 'Max consumptions reached.'
      case 'expired_transaction_request':
        return 'Transaction Expired.'
      default:
        return 'Expired.'
    }
  }
  renderActivityList = () => {
    return (
      <ConsumptionFetcherByTransactionIdFetcher
        id={queryString.parse(this.props.location.search)['show-request-tab']}
        render={({ data, individualLoadingStatus, pagination }) => {
          return (
            <ContentContainer>
              <SortableTable
                rows={data}
                columns={this.columns}
                loadingStatus={individualLoadingStatus}
                rowRenderer={this.rowRenderer}
                onClickRow={this.onClickRow}
                isFirstPage={pagination.is_first_page}
                isLastPage={pagination.is_last_page}
                navigation
                pageEntity={'page-activity'}
              />
            </ContentContainer>
          )
        }}
        query={{
          page: queryString.parse(this.props.location.search)['page-activity'],
          perPage: Math.floor(window.innerHeight / 65),
          uniqueId: queryString.parse(this.props.location.search)['show-request-tab']
        }}
      />
    )
  }
  renderProperties = transactionRequest => {
    const valid = transactionRequest.status === 'valid'
    return (
      <TransactionReqeustPropertiesContainer>
        <ConsumeActionContainer onSubmit={this.onSubmitConsume(transactionRequest)}>
          <QrContainer>
            <QR data={transactionRequest.id} />
            <QrTypeContainer>
              <b>Type:</b>
              <div>{transactionRequest.type}</div>
            </QrTypeContainer>
            <QrTypeContainer>
              <b>Token:</b>
              <div>{_.get(transactionRequest, 'token.name')}</div>
            </QrTypeContainer>
          </QrContainer>
          <InputsContainer>
            <AllWalletsFetcher
              query={{ search: this.state.consumeAddress }}
              render={({ data }) => {
                return (
                  <InputLabelContainer>
                    <InputLabel disabled={!valid}>Wallet</InputLabel>
                    <Select
                      disabled={!valid}
                      normalPlaceholder='acc_0x000000000000000'
                      onSelectItem={this.onSelectWalletAddressSelect}
                      value={this.state.consumeAddress}
                      onChange={this.onChangeWalletInput}
                      options={data.map(d => {
                        return {
                          key: d.address,
                          value: `${d.address} ( ${_.get(d, 'account.name') ||
                            _.get(d, 'user.username') ||
                            _.get(d, 'user.email')} )`
                        }
                      })}
                    />
                  </InputLabelContainer>
                )
              }}
            />
            <TokensFetcher
              render={({ data }) => {
                return (
                  <TokenAmountContainer>
                    <InputLabelContainer>
                      <InputLabel disabled={!valid}>Amount</InputLabel>
                      <Input
                        normalPlaceholder='1000'
                        onChange={this.onChangeAmount}
                        value={this.state.amount}
                        type='number'
                        disabled={!valid || !transactionRequest.allow_amount_override}
                      />
                    </InputLabelContainer>
                    <InputLabelContainer>
                      <InputLabel disabled={!valid}>Token</InputLabel>
                      <Select
                        disabled={!valid}
                        normalPlaceholder='ETH'
                        onSelectItem={this.onSelectTokenSelect}
                        onChange={this.onChangeSearchToken}
                        value={this.state.searchTokenValue}
                        options={data.map(token => ({
                          ...{
                            key: token.id,
                            value: `${token.name} (${token.symbol})`
                          },
                          ...token
                        }))}
                      />
                    </InputLabelContainer>
                  </TokenAmountContainer>
                )
              }}
            />
            {transactionRequest.expiration_reason ? (
              <ExpiredContainer>
                {this.getExpiredReason(transactionRequest.expiration_reason)}
              </ExpiredContainer>
            ) : (
              <Button disabled={!valid} loading={this.state.submitStatus === 'SUBMITTING'}>
                Consume
              </Button>
            )}
            <Error error={this.state.error}>{this.state.error}</Error>
          </InputsContainer>
        </ConsumeActionContainer>
        <AdditionalRequestDataContainer>
          <h5>ADDITIONAL REQUEST DETAILS</h5>
          <InformationItem>
            <b>Type:</b> {transactionRequest.type}
          </InformationItem>
          <InformationItem>
            <b>Token ID:</b> {_.get(transactionRequest, 'token.id')}
          </InformationItem>
          <InformationItem>
            <b>Amount:</b>{' '}
            {formatNumber(
              (transactionRequest.amount || 0) / _.get(transactionRequest, 'token.subunit_to_unit')
            )}{' '}
            {_.get(transactionRequest, 'token.symbol')}
          </InformationItem>
          <InformationItem>
            <b>address:</b> {transactionRequest.address}
          </InformationItem>
          <InformationItem>
            <b>Confirmation:</b> {transactionRequest.require_confirmation ? 'Yes' : 'No'}
          </InformationItem>
          <InformationItem>
            <b>Max Consumptions:</b> {transactionRequest.max_consumptions || '-'}
          </InformationItem>
          <InformationItem>
            <b>Max Consumptions User:</b> {transactionRequest.max_consumptionPerUser || '-'}
          </InformationItem>
          <InformationItem>
            <b>Expiry Date:</b> {transactionRequest.expiration_date || '-'}
          </InformationItem>
          <InformationItem>
            <b>Allow Override:</b> {transactionRequest.allow_amount_override ? 'Yes' : 'No'}
          </InformationItem>
          <InformationItem>
            <b>Coorelation ID:</b> {transactionRequest.correlation_id || '-'}
          </InformationItem>
        </AdditionalRequestDataContainer>
      </TransactionReqeustPropertiesContainer>
    )
  }

  render = () => {
    return (
      <TransactionRequestProvider
        transactionRequestId={queryString.parse(this.props.location.search)['show-request-tab']}
        render={({ transactionRequest: tq }) => {
          return (
            <PanelContainer>
              <Icon name='Close' onClick={this.onClickClose} />
              <h4>
                Request to {tq.type}{' '}
                {formatNumber((tq.amount || 0) / _.get(tq, 'token.subunit_to_unit'))}{' '}
                {_.get(tq, 'token.symbol')}
              </h4>
              <SubDetailTitle>
                <span>{tq.id}</span> | <span>{tq.type}</span> |{' '}
                <span>{tq.user_id || _.get(tq, 'account.name')}</span>
              </SubDetailTitle>
              <TabPanel
                activeTabKey={
                  queryString.parse(this.props.location.search)['active-tab'] || 'activity'
                }
                onClickTab={this.onClickTab}
                data={[
                  {
                    key: 'activity',
                    tabTitle: 'ACTIVITY LIST',
                    tabContent: this.renderActivityList()
                  },
                  {
                    key: 'properties',
                    tabTitle: 'PROPERTIES',
                    tabContent: this.renderProperties(tq)
                  }
                ]}
              />
            </PanelContainer>
          )
        }}
      />
    )
  }
}

export default enhance(TransactionRequestPanel)
