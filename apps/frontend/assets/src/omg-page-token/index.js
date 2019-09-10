import React, { Component } from 'react'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
import styled from 'styled-components'

import { openModal } from '../omg-modal/action'
import TopNavigation from '../omg-page-layout/TopNavigation'
import SortableTable from '../omg-table'
import { Button, Avatar } from '../omg-uikit'
import TokensFetcher from '../omg-token/tokensFetcher'
import CreateTokenChooser from '../omg-token/CreateTokenChooser'
import { createSearchTokenQuery } from '../omg-token/searchField'
import { NameColumn } from '../omg-page-account'

const TokenPageContainer = styled.div`
  position: relative;
  td:nth-child(1) {
    border: none;
    position: relative;
    white-space: nowrap;
    :before {
      content: '';
      position: absolute;
      right: 0;
      bottom: -1px;
      height: 1px;
      width: calc(100% - 50px);
      border-bottom: 1px solid ${props => props.theme.colors.S200};
    }
  }
  td:nth-child(4) {
    white-space: nowrap;
  }
`
const columns = [
  { key: 'token', title: 'TOKEN NAME', sort: true },
  { key: 'blockchain', title: 'TYPE', sort: false },
  { key: 'created', title: 'CREATED AT', sort: true },
  { key: 'id', title: 'TOKEN ID', sort: true },
  { key: 'symbol', title: 'SYMBOL', sort: true }
]

class TokenDetailPage extends Component {
  static propTypes = {
    divider: PropTypes.bool,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    openModal: PropTypes.func
  }
  onClickLoadMore = e => {
    this.setState(({ loadMoreTime }) => ({ loadMoreTime: loadMoreTime + 1 }))
  }
  renderCreateTokenButton = refetch => {
    return (
      <CreateTokenChooser
        style={{ marginLeft: '10px' }}
        key='create-token-chooser'
        refetch={refetch}
        onClickCreateInternalToken={() => {
          this.props.openModal({ id: 'createTokenModal', onFetchSuccess: refetch })
        }}
        {...this.props}
      />
    )
  }
  renderCreateExchangePairButton = () => {
    return (
      <Button
        key='create pair'
        size='small'
        styleType='secondary'
        onClick={() => {
          this.props.openModal({ id: 'exchangePairModal', action: 'create' })
        }}
      >
        <span>Create Exchange Pair</span>
      </Button>
    )
  }
  rowRenderer (key, data, rows) {
    if (key === 'blockchain') {
      return data
        ? 'Blockchain'
        : 'Internal'
    }
    if (key === 'created') {
      return moment(data).format()
    }
    if (key === 'token') {
      return (
        <NameColumn>
          <Avatar image={rows.avatar} name={rows.symbol} /><span>{data}</span>
        </NameColumn>
      )
    }
    return data
  }
  onClickRow = (data, index) => e => {
    this.props.history.push(`/tokens/${data.id}`)
  }
  renderTokenPage = ({ data: tokens, individualLoadingStatus, pagination, fetch }) => {
    const data = tokens.map(token => {
      return {
        key: token.id,
        token: token.name,
        symbol: token.symbol,
        created: token.created_at,
        id: token.id,
        blockchain: !!token.blockchain_status
      }
    })

    return (
      <TokenPageContainer>
        <TopNavigation
          divider={this.props.divider}
          title={'Tokens'}
          buttons={[
            tokens.length > 1 ? this.renderCreateExchangePairButton() : null,
            this.renderCreateTokenButton(fetch)
          ]}
        />
        <SortableTable
          rows={data}
          columns={columns}
          loadingStatus={individualLoadingStatus}
          perPage={20}
          onClickRow={this.onClickRow}
          rowRenderer={this.rowRenderer}
          isFirstPage={pagination.is_first_page}
          isLastPage={pagination.is_last_page}
          navigation
        />
      </TokenPageContainer>
    )
  }

  render () {
    return (
      <TokensFetcher
        render={this.renderTokenPage}
        {...this.state}
        {...this.props}
        query={{
          page: queryString.parse(this.props.location.search).page,
          perPage: 10,
          ...createSearchTokenQuery(queryString.parse(this.props.location.search).search)
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

const enhance = compose(
  withRouter,
  connect(
    null,
    { openModal }
  )
)

export default enhance(TokenDetailPage)
