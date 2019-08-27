/* eslint-disable react/prop-types */
/* eslint-disable react/display-name */
import React from 'react'
import { withRouter } from 'react-router'
import queryString from 'query-string'
import styled from 'styled-components'
import PropTypes from 'prop-types'

import TabMenu from './TabMenu'

import TransactionsFetcher from '../omg-transaction/transactionsFetcher'
import TransactionTable from '../omg-page-transaction/TransactionTable'

const TopRow = styled.div`
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  margin-bottom: 10px;
`

const renderBlockchainTransactionPage = address => ({
  data,
  individualLoadingStatus,
  pagination
}) => {
  const transactions = _.filter(data, i => {
    return i.from_blockchain_address === address || i.to_blockchain_address === address
  })
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
  return (
    <>
      <TopRow>
        <TabMenu />
      </TopRow>
      <TransactionsFetcher
        render={renderBlockchainTransactionPage(address)}
        query={{
          page: queryString.parse(location.search).page,
          perPage: Math.floor(window.innerHeight / 100),
          search: queryString.parse(location.search).search
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
