import React, { Component } from 'react'
import PropTypes from 'prop-types'
import TokenMintedHistoryFetcher from '../omg-token/tokenMintedHistoryFetcher'
import Table from '../omg-table'
import queryString from 'query-string'
import { withRouter } from 'react-router-dom'
import moment from 'moment'
import { formatReceiveAmountToTotal } from '../utils/formatter'
export default withRouter(
  class HistoryTable extends Component {
    static propTypes = {
      tokenId: PropTypes.string,
      location: PropTypes.object
    }
    constructor (props) {
      super(props)
      this.columns = [
        { key: 'id', title: 'MINTING ID', sort: true },
        { key: 'amount', title: 'AMOUNT', sort: true },
        { key: 'to', title: 'TO ADDRESS', sort: true },
        { key: 'created_by', title: 'MINTED BY' },
        { key: 'created_at', title: 'CREATED DATE', sort: true }
      ]
    }
    rowRenderer = (key, data, rows) => {
      if (key === 'amount') {
        return `${formatReceiveAmountToTotal(data, rows.token.subunit_to_unit)} ${_.get(
          rows,
          'token.symbol'
        )}`
      }
      if (key === 'to') {
        return _.get(rows, 'transaction.to.address')
      }
      if (key === 'created_at') {
        return moment(data).format('DD/MM/YYYY hh:mm:ss')
      }
      if (key === 'created_by') {
        return _.get(rows, 'account.name')
      }
      return data
    }
    renderTableHistory = ({ data, individualLoadingStatus, pagination, fetch }) => {
      return (
        <Table
          rows={data}
          columns={this.columns}
          loadingStatus={individualLoadingStatus}
          rowRenderer={this.rowRenderer}
          isFirstPage={pagination.is_first_page}
          isLastPage={pagination.is_last_page}
          navigation
        />
      )
    }
    render () {
      return (
        <TokenMintedHistoryFetcher
          tokenId={this.props.tokenId}
          render={this.renderTableHistory}
          query={{
            page: queryString.parse(this.props.location.search).page,
            perPage: Math.floor(window.innerHeight / 65),
            search: queryString.parse(this.props.location.search).search
          }}
        />
      )
    }
  }
)
