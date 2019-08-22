import React, { useCallback } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import { useDispatch } from 'react-redux'

import { Id, Icon, Button } from '../omg-uikit'
import SortableTable from '../omg-table'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { AllBlockchainWalletsFetcher } from '../omg-blockchain-wallet/blockchainwalletsFetcher'
import { openModal } from '../omg-modal/action'

const SortableTableContainer = styled.div`
  position: relative;
`
const WalletAddressContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i[name='Wallet'] {
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
    margin-right: 10px;
  }
`

const BlockchainWalletsPage = ({ match, history }) => {
  const dispatch = useDispatch()

  const onClickCreateWallet = () => openModal({ id: 'blockchainWalletModal' })(dispatch)

  const renderCreateWalletButton = () => {
    return (
      <Button
        key='create-wallet-button'
        size='small'
        styleType='secondary'
        onClick={onClickCreateWallet}
      >
        <Icon name='Plus' />
        <span>Create Wallet</span>
      </Button>
    )
  }

  const rowRenderer = (key, data, rows) => {
    if (key === 'name') {
      return (
        <WalletAddressContainer>
          <Icon name='Wallet' />
          <span>{data || 'Blockchain Wallet'}</span>
        </WalletAddressContainer>
      )
    }
    if (key === 'address') {
      return <Id withCopy>{data}</Id>
    }
  }

  const columns = [
    { key: 'name', title: 'WALLET NAME', sort: true },
    { key: 'address', title: 'ADDRESS', sort: false }
  ]

  const onClickRow = (data, index) => e => {
    history.push(`${match.path}/${data.address}/tokens`)
  }

  return (
    <div>
      <TopNavigation
        divider
        title='Blockchain Wallets'
        description='These are your blockchain wallets. Click one to view its details.'
        searchBar={false}
        buttons={[renderCreateWalletButton()]}
      />
      <AllBlockchainWalletsFetcher
        query={{ perPage: Math.floor(window.innerHeight / 65) }}
        render={({ blockchainWallets, individualLoadingStatus, pagination }) => {
          return (
            <SortableTableContainer loadingStatus={individualLoadingStatus}>
              <SortableTable
                rows={blockchainWallets}
                columns={columns}
                loadingStatus={individualLoadingStatus}
                rowRenderer={rowRenderer}
                onClickRow={onClickRow}
                isFirstPage={pagination.is_first_page}
                isLastPage={pagination.is_last_page}
                navigation
              />
            </SortableTableContainer>
          )
        }}
      />
    </div>
  )
}

BlockchainWalletsPage.propTypes = {
  history: PropTypes.object,
  match: PropTypes.object
}

export default BlockchainWalletsPage
