/* eslint-disable react/prop-types */
/* eslint-disable react/display-name */
import React, { useState } from 'react'
import { withRouter } from 'react-router'
import queryString from 'query-string'
import styled from 'styled-components'
import PropTypes from 'prop-types'

import TabMenu from './TabMenu'

import { SearchBar, Button, Icon } from '../omg-uikit'
import AdvancedFilter from '../omg-advanced-filter'
import TransactionsFetcher from '../omg-transaction/transactionsFetcher'
import TransactionTable from '../omg-page-transaction/TransactionTable'

const TopRow = styled.div`
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  margin-bottom: 10px;
`
const Actions = styled.div`
  display: flex;
  flex-direction: row;
  button {
    margin-left: 10px;
    i {
      margin-right: 5px;
    }
  }
`

const renderBlockchainTransactionPage = ({
  data: transactions,
  individualLoadingStatus,
  pagination
}) => {
  return (
    <TransactionTable
      loadingStatus={individualLoadingStatus}
      pagination={pagination}
      transactions={transactions}
    />
  )
}

const BlockchainTransactionsPage = ({ location, match }) => {
  const { address } = match.params

  const [ advancedFilterModalOpen, setAdvancedFilterModalOpen ] = useState(false)
  const [ matchAll, setMatchAll ] = useState([])
  const [ matchAny, setMatchAny ] = useState([])

  return (
    <>
      <TopRow>
        <TabMenu />
        <Actions>
          <SearchBar />
          <Button
            key='filter'
            size='small'
            styleType='secondary'
            onClick={() => setAdvancedFilterModalOpen(true)}
          >
            <Icon name='Filter' />
            <span>Filter</span>
          </Button>
        </Actions>
      </TopRow>
      <AdvancedFilter
        title='Filter Transactions'
        page='blockchain_transactions'
        open={advancedFilterModalOpen}
        onRequestClose={() => setAdvancedFilterModalOpen(false)}
        onFilter={({ matchAll: _matchAll, matchAny: _matchAny }) => {
          setMatchAll(_matchAll)
          setMatchAny(_matchAny)
        }}
      />
      <TransactionsFetcher
        render={renderBlockchainTransactionPage}
        query={{
          page: queryString.parse(location.search).page,
          perPage: Math.floor(window.innerHeight / 100),
          search: queryString.parse(location.search).search,
          matchAll,
          matchAny: [
            { field: 'to_blockchain_address', comparator: 'contains', value: address },
            { field: 'from_blockchain_address', comparator: 'contains', value: address },
            ...matchAny
          ]
        }}
      />
    </>
  )
}

BlockchainTransactionsPage.propTypes = {
  location: PropTypes.object,
  match: PropTypes.object
}

export default withRouter(BlockchainTransactionsPage)
