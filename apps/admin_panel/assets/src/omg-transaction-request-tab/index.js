import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import TabPanel from './TabPanel'
import SortableTable from '../omg-table'
import ConsumptionFetcherByTransactionIdFetcher from '../omg-consumption/consumptionByTransactionIdFetcher'
import TransactionRequestProvider from '../omg-transaction-request/transactionRequestProvider'
import { Icon } from '../omg-uikit'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
import QRCode from 'qrcode'
const PanelContainer = styled.div`
  height: 100vh;
  position: fixed;
  right: 0;
  width: 550px;
  background-color: white;
  padding: 40px 20px;
  box-shadow: 0 0 15px 0 rgba(4, 7, 13, 0.1);
  > i {
    position: absolute;
    right: 25px;
    color: ${props => props.theme.colors.S500};
    top: 25px;
    cursor: pointer;
  }
`
const TransactionReqeustPropertiesContainer = styled.div`
  > img {
    width: 150px;
    height: 150px;
    border: 1px solid ${props => props.theme.colors.BL400};
    margin-bottom: 30px;
    margin-top: 30px;
  }
  > div {
    margin-bottom: 10px;
  }
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
class QR extends Component {
  static propTypes = {
    data: PropTypes.object
  }
  state = {}
  componentDidMount = async () => {
    const dataUrl = await QRCode.toDataURL(this.props.data)
    this.setState({ dataUrl })
  }
  componentDidUpdate = async nextProps => {
    if (this.props.data !== nextProps.data) {
      const dataUrl = await QRCode.toDataURL(this.props.data)
      this.setState({ dataUrl })
    }
  }
  render () {
    return <img src={this.state.dataUrl} />
  }
}
class TransactionRequestPanel extends Component {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object
  }
  constructor (props) {
    super(props)
    this.columns = [
      { key: 'id', title: 'REQUEST ID', sort: true },
      { key: 'type', title: 'TYPE', sort: true },
      { key: 'amount', title: 'AMOUNT', sort: true },
      { key: 'created_by', title: 'CREATED BY' },
      { key: 'created_at', title: 'CREATED DATE', sort: true },
      { key: 'require_confirmation', title: 'CONFIRMATION' }
    ]
  }
  renderActivityList = () => {
    return (
      <ConsumptionFetcherByTransactionIdFetcher
        id={queryString.parse(this.props.location.search)['show-request-tab']}
        render={({ data, individualLoadingStatus, pagination }) => {
          return (
            <div>
              <SortableTable
                rows={data}
                columns={this.columns}
                loadingStatus={individualLoadingStatus}
                rowRenderer={this.rowRenderer}
                onClickRow={this.onClickRow}
                isFirstPage={pagination.is_first_page}
                isLastPage={pagination.is_last_page}
                navigation
              />
            </div>
          )
        }}
        query={{
          page: 1,
          perPage: 10,
          uniqueId: queryString.parse(this.props.location.search)['show-request-tab']
        }}
      />
    )
  }
  renderProperties = transactionRequest => {
    return (
      <TransactionRequestProvider
        transactionRequestId={queryString.parse(this.props.location.search)['show-request-tab']}
        render={({ transactionRequest }) => {
          return (
            <TransactionReqeustPropertiesContainer>
              <QR data={transactionRequest.id} />
              <div>
                <b>Type:</b> {transactionRequest.type}
              </div>
              <div>
                <b>Token ID:</b> {_.get(transactionRequest, 'token.id')}
              </div>
              <div>
                <b>Amount:</b> {transactionRequest.amount || 0}
              </div>
              <div>
                <b>address:</b> {transactionRequest.address}
              </div>
              <div>
                <b>Confirmation:</b> {transactionRequest.require_confirmation ? 'Yes' : 'No'}
              </div>
              <div>
                <b>Max Consumptions:</b> {transactionRequest.max_consumtions || '-'}
              </div>
              <div>
                <b>Max Consumptions User:</b> {transactionRequest.max_consumptionPerUser || '-'}
              </div>
              <div>
                <b>Expiry Date:</b> {transactionRequest.expiration_date}
              </div>
              <div>
                <b>Allow Override:</b> {transactionRequest.allow_amount_overide ? 'Yes' : 'No'}
              </div>
              <div>
                <b>Coorelation ID:</b> {transactionRequest.correlation_id}
              </div>
            </TransactionReqeustPropertiesContainer>
          )
        }}
      />
    )
  }
  onClickClose = () => {
    const searchObject = queryString.parse(this.props.location.search)
    delete searchObject['active-tab']
    delete searchObject['show-request-tab']
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
  render = () => {
    return (
      <TransactionRequestProvider
        transactionRequestId={queryString.parse(this.props.location.search)['show-request-tab']}
        render={({ transactionRequest: tq }) => {
          return (
            <PanelContainer>
              <Icon name='Close' onClick={this.onClickClose} />
              <h4>
                Request to {tq.type} {tq.amount || 0} {_.get(tq, 'token.symbol')}
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

export default withRouter(TransactionRequestPanel)
