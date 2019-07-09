import React from 'react'
import styled from 'styled-components'

import TabMenu from './TabMenu'

const TopRow = styled.div`
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  margin-bottom: 10px;
`

const BlockchainTransactionsPage = () => {
  return (
    <>
      <TopRow>
        <TabMenu />
      </TopRow>
      BlockchainTransactionsPage
    </>
  )
}

export default BlockchainTransactionsPage
