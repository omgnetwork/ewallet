import React, { Component } from 'react'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
import styled from 'styled-components'
import _ from 'lodash'

import { openModal } from 'omg-modal/action'
import TopNavigation from 'omg-page-layout/TopNavigation'
import SortableTable from 'omg-table'
import { Button, Avatar, Icon, Tooltip } from 'omg-uikit'
import TokensFetcher from 'omg-token/tokensFetcher'
import CreateTokenChooser from 'omg-token/CreateTokenChooser'
import { createSearchTokenQuery } from 'omg-token/searchField'
import { NameColumn } from 'omg-page-account'
import { selectInternalEnabled } from 'omg-configuration/selector'

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
  .create-token-chooser {
    margin-left: 20px;
  }
`
const EWalletBlockchain = styled.div`
  display: flex;
  align-items: center;
  i {
    margin-left: 5px;
    font-size: 12px;
  }
  .triangle {
    right: 2px;
  }
  .tooltip-text {
    width: 200px;
    transform: translateX(50%);
    top: -54px;
  }
`
const columns = [
  { key: 'token', title: 'TOKEN NAME', sort: true },
  { key: 'blockchainStatus', title: 'TYPE', sort: true },
  { key: 'status', title: 'STATUS', sort: true },
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
    openModal: PropTypes.func,
    internalEnabled: PropTypes.bool
  }

  renderCreateTokenButton = refetch => {
    return (
      <CreateTokenChooser
        key='create-token-chooser'
        externalStyles='create-token-chooser'
        refetch={refetch}
        internalEnabled={this.props.internalEnabled}
      />
    )
  }
  renderCreateExchangePairButton = () => {
    return (
      <Button
        key='create-exchange-pair'
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
    if (key === 'status') {
      if (rows.blockchainStatus) {
        return _.capitalize(rows.blockchainStatus)
      }
    }
    if (key === 'blockchainStatus') {
      if (rows.txHash) {
        return (
          <EWalletBlockchain>
            <span>Blockchain</span>
            <Tooltip text='This is a blockchain token controlled by the eWallet.'>
              <Icon name='Wallet' />
            </Tooltip>
          </EWalletBlockchain>
        )
      }

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
        blockchainStatus: token.blockchain_status,
        txHash: token.tx_hash
      }
    })

    return (
      <TokenPageContainer>
        <TopNavigation
          divider={this.props.divider}
          title={'Tokens'}
          buttons={[
            this.props.internalEnabled && tokens.length > 1 ? this.renderCreateExchangePairButton() : null,
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
    state => ({ internalEnabled: selectInternalEnabled()(state)}),
    { openModal }
  )
)

export default enhance(TokenDetailPage)
