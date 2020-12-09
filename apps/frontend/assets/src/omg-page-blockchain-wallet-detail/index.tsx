import React, { useEffect, useState } from 'react'
import { Route, Switch, Redirect, RouteComponentProps } from 'react-router-dom'
import { connect, useDispatch, useSelector } from 'react-redux'
import _ from 'lodash'

import {
  selectBlockchainWalletById,
  selectPlasmaDepositByAddress
} from 'omg-blockchain-wallet/selector'
import {
  getAllBlockchainWallets,
  getBlockchainWalletBalance
} from 'omg-blockchain-wallet/action'
import TopNavigation from 'omg-page-layout/TopNavigation'
import { getTransactionById } from 'omg-transaction/action'
import { Button } from 'omg-uikit'
import theme from 'adminPanelApp/theme'

import BlockchainActionSelector from './BlockchainActionSelector'
import BlockchainSettingsPage from './BlockchainSettingsPage'
import BlockchainTransactionsPage from './BlockchainTransactionsPage'
import BlockchainTokensPage from './BlockchainTokensPage'

interface BlockchainWalletDetailPageProps extends RouteComponentProps {
  getAllBlockchainWallets: Function
  getBlockchainWalletBalance: Function
}

const BlockchainWalletDetailPage = ({
  match,
  getAllBlockchainWallets,
  getBlockchainWalletBalance
}: BlockchainWalletDetailPageProps) => {
  const dispatch = useDispatch()
  const address = _.get(match, ['params', 'address'])

  const walletType = useSelector(state =>
    selectBlockchainWalletById(state)(address)
  ).type

  const [pollingState, setPollingState] = useState<boolean>(false)

  const latestDeposit = useSelector(selectPlasmaDepositByAddress(address))

  useEffect(() => {
    if (!walletType) {
      getAllBlockchainWallets({
        page: 1,
        perPage: 10
      })
    }
  }, [getAllBlockchainWallets, walletType])

  useEffect(() => {
    if (pollingState) {
      const pollBalance = async () => {
        try {
          const { id } = latestDeposit
          const { data } = await getTransactionById(id)(dispatch)

          if (data.status === 'confirmed') {
            getBlockchainWalletBalance({
              address: address,
              cacheKey: { address: address, entity: 'plasmadeposits' }
            })
            clearInterval(balancePolling)
            setPollingState(false)
          } else {
            _.noop() /* Keep polling until confirmed */
          }
        } catch (e) {
          clearInterval(balancePolling)
          setPollingState(false)
        }
      }
      const balancePolling = setInterval(pollBalance, 2000)
      return () => clearInterval(balancePolling)
    }
  }, [
    address,
    dispatch,
    getBlockchainWalletBalance,
    latestDeposit,
    pollingState
  ])

  const renderActionButtons = () => {
    const ethereumActions = [
      {
        name: 'Transfer to Cold Wallet',
        modal: { id: 'hotWalletTransferModal' },
        icon: 'Transaction'
      }
    ]

    const plasmaActions = [
      {
        name: 'Deposit to the OMG Network',
        modal: {
          id: 'plasmaDepositModal',
          args: { onDepositComplete: () => setPollingState(true) }
        },
        icon: 'Download'
      }
    ]

    if (walletType === 'hot') {
      return (
        <>
          <Button
            size="small"
            styleType="secondary"
            style={{
              color: theme.colors.B300,
              borderColor: theme.colors.B300,
              borderWidth: '0px',
              borderBottom: `1px solid ${theme.colors.B300}`,
              borderRadius: '0px',
              marginRight: '20px'
            }}
            disabled
          >
            <span>Manage Your Tokens</span>
          </Button>
          <BlockchainActionSelector
            name="OMG Network"
            fromAddress={address}
            actions={plasmaActions}
          />
          <BlockchainActionSelector
            name="Ethereum"
            fromAddress={address}
            actions={ethereumActions}
          />
        </>
      )
    }
  }

  return (
    <>
      <TopNavigation
        divider
        title="Blockchain Wallet"
        types={false}
        searchBar={false}
        description={address}
        buttons={[renderActionButtons()]}
      />
      <Switch>
        <Route
          exact
          path={`${match.path}/tokens`}
          component={BlockchainTokensPage}
        />
        <Route
          exact
          path={`${match.path}/blockchain_transactions`}
          component={BlockchainTransactionsPage}
        />
        <Route
          exact
          path={`${match.path}/blockchain_settings`}
          component={BlockchainSettingsPage}
        />
        <Redirect to={`${match.path}/tokens`} />
      </Switch>
    </>
  )
}

export default connect(null, {
  getAllBlockchainWallets,
  getBlockchainWalletBalance
})(BlockchainWalletDetailPage)
