import React, { Component } from 'react'
import PropTypes from 'prop-types'
import queryString from 'query-string'
import styled from 'styled-components'
import ConsumptionFetcherByTransactionIdFetcher from '../omg-consumption/consumptionByTransactionIdFetcher'
import SortableTable from '../omg-table'
import { withRouter } from 'react-router-dom'
import moment from 'moment'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import { Icon } from '../omg-uikit'
import { compose } from 'recompose'
import { connect } from 'react-redux'
import { approveConsumptionById, rejectConsumptionById } from '../omg-consumption/action'
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
const enhance = compose(
  withRouter,
  connect(
    null,
    { approveConsumptionById, rejectConsumptionById }
  )
)

class ActivityList extends Component {
  static propTypes = {
    location: PropTypes.object,
    history: PropTypes.object,
    approveConsumptionById: PropTypes.func,
    rejectConsumptionById: PropTypes.func
  }
  constructor (props) {
    super(props)
    this.columns = [
      { key: 'estimated_consumption_amount', title: 'AMOUNT' },
      { key: 'to', title: 'CONSUMER' },
      { key: 'created_at', title: 'CREATED DATE' },
      { key: 'status', title: 'CONFIRMATION' }
    ]
    this.perPage = Math.floor(window.innerHeight / 60)
  }
  onClickConfirm = (id, fetch, pendingConsumption) => async e => {
    e.stopPropagation()
    if (pendingConsumption.length - 1 === this.perPage) {
      fetch()
    }
    await this.props.approveConsumptionById(id)
  }
  onClickReject = (id, fetch, pendingConsumption) => e => {
    e.stopPropagation()
    if (pendingConsumption.length - 1 === this.perPage) {
      fetch()
    }
    this.props.rejectConsumptionById(id)
  }
  onClickRow = (data, index) => e => {
    const searchObject = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        'show-consumption-tab': data.id
      })
    })
  }
  rowRenderer = (fetch, pendingConsumption) => (key, data, rows) => {
    if (key === 'estimated_consumption_amount') {
      return (
        <div>
          {formatReceiveAmountToTotal(data, _.get(rows, 'token.subunit_to_unit'))}{' '}
          {_.get(rows, 'token.symbol')}
        </div>
      )
    }
    if (key === 'created_at') {
      return moment(data).format()
    }
    if (key === 'to') {
      return <div>{rows.user_id || _.get(rows, 'account.name')}</div>
    }

    if (key === 'status') {
      switch (data) {
        case 'pending':
          return (
            <div>
              <ConfirmButtonApprove
                onClick={this.onClickConfirm(rows.id, fetch, pendingConsumption)}
              >
                <Icon name='Checked' />
              </ConfirmButtonApprove>
              <ConfirmButtonReject onClick={this.onClickReject(rows.id, fetch, pendingConsumption)}>
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
  render () {
    return (
      <ConsumptionFetcherByTransactionIdFetcher
        id={queryString.parse(this.props.location.search)['show-request-tab']}
        render={({ data: pendingConsumption, individualLoadingStatus, pagination, fetch }) => {
          return (
            <ContentContainer>
              <SortableTable
                rows={pendingConsumption.slice(0, this.perPage)}
                columns={this.columns}
                loadingStatus={individualLoadingStatus}
                rowRenderer={this.rowRenderer(fetch, pendingConsumption)}
                onClickRow={this.onClickRow}
                pageEntity={'page-activity'}
              />
            </ContentContainer>
          )
        }}
        query={{
          page: 1,
          perPage: this.perPage * 2,
          searchTerms: { status: 'pending' },
          transactionRequestId: queryString.parse(this.props.location.search)['show-request-tab']
        }}
      />
    )
  }
}

export default enhance(ActivityList)
