import React, { Component } from 'react'
import PropTypes from 'prop-types'
import queryString from 'query-string'
import styled from 'styled-components'
import ConsumptionFetcherByTransactionIdFetcher from '../omg-consumption/consumptionByTransactionIdFetcher'
import SortableTable from '../omg-table'
import { withRouter } from 'react-router-dom'
import moment from 'moment'
import { formatNumber } from '../utils/formatter'
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
      { key: 'amount', title: 'AMOUNT' },
      { key: 'to', title: 'TO' },
      { key: 'created_at', title: 'CREATED DATE' },
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
  onClickRow = (data, index) => e => {
    const searchObject = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        [`show-consumption-tab`]: data.id
      })
    })
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
  render () {
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
}

export default enhance(ActivityList)
