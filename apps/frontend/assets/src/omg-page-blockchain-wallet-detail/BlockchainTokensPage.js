import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import queryString from 'query-string'

import TabMenu from './TabMenu'
import SortableTable from '../omg-table'
import { Button, Icon, Avatar } from '../omg-uikit'
import { BlockchainWalletBalanceFetcher } from '../omg-blockchain-wallet/blockchainwalletsFetcher'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import AdvancedFilter from '../omg-advanced-filter'

const BlockchainTokensPageContainer = styled.div`
  position: relative;
  padding-bottom: 50px;
  td {
    white-space: nowrap;
  }
  td:first-child {
    border: none;
    position: relative;
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
  td:nth-child(2) {
    width: 150px;
    max-width: 150px;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  tr:hover {
    td:nth-child(1) {
      i {
        visibility: visible;
      }
    }
  }
  i[name='Copy'] {
    cursor: pointer;
    visibility: hidden;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B300};
    }
  }
  i[name='Filter'] {
    cursor: pointer;
    margin-right: 10px;
  }
`
const SortableTableContainer = styled.div`
  position: relative;
`
const TokenColumn = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
  > span {
    margin-left: 10px;
  }
`
const TopRow = styled.div`
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  margin-bottom: 10px;
`
// const ActionButtons = styled.div`
//   display: flex;
//   flex-direction: row;
//   button {
//     margin-left: 20px;
//   }
// `
class BlockchainTokensPage extends Component {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object,
    match: PropTypes.object
  }
  constructor (props) {
    super(props)
    this.columns = [
      { key: 'name', title: 'TOKEN', sort: true },
      { key: 'balance', title: 'BALANCE', sort: true }
    ]
  }
  state = {
    advancedFilterModalOpen: false,
    matchAll: [],
    matchAny: []
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'name') {
      return (
        <TokenColumn>
          <Avatar name={rows.token.symbol} />
          <span>{rows.token.name}</span>
        </TokenColumn>
      )
    }
    if (key === 'balance') {
      return `${formatReceiveAmountToTotal(rows.amount, rows.token.subunit_to_unit)} ${rows.token.symbol}`
    }
    return data
  }
  renderAdvancedFilterButton = () => {
    return (
      <Button
        key='filter'
        size='small'
        styleType='secondary'
        onClick={() => this.setState({ advancedFilterModalOpen: true })}
      >
        <Icon name='Filter' /><span>Filter</span>
      </Button>
    )
  }
  renderBlockchainTokenpage = ({
    data,
    individualLoadingStatus,
    pagination
  }) => {
    return (
      <BlockchainTokensPageContainer>
        <TopRow>
          <TabMenu />
          {/* <ActionButtons>
            <SearchBar placeholder='Search token' />
            {this.renderAdvancedFilterButton()}
          </ActionButtons> */}
        </TopRow>
        <AdvancedFilter
          title='Filter Tokens'
          page='blockchain-tokens'
          open={this.state.advancedFilterModalOpen}
          onRequestClose={() => this.setState({ advancedFilterModalOpen: false })}
          onFilter={({ matchAll, matchAny }) => this.setState({ matchAll, matchAny })}
        />
        <SortableTableContainer
          ref={table => (this.table = table)}
          loadingStatus={individualLoadingStatus}
        >
          <SortableTable
            rows={data}
            columns={this.columns}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
          />
        </SortableTableContainer>
      </BlockchainTokensPageContainer>
    )
  }

  render () {
    return (
      <BlockchainWalletBalanceFetcher
        render={this.renderBlockchainTokenpage}
        {...this.state}
        {...this.props}
        query={{
          address: this.props.match.params.address,
          page: queryString.parse(this.props.location.search).page,
          perPage: Math.floor(window.innerHeight / 65),
          matchAll: this.state.matchAll,
          matchAny: this.state.matchAny,
          searchTerm: {
            id: queryString.parse(this.props.location.search).search
          }
        }}
      />
    )
  }
}

export default withRouter(BlockchainTokensPage)
