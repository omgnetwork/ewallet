import React, { useEffect, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import styled from 'styled-components'

import { Button } from '../omg-uikit'
import CreateBlockchainTransactionButton from '../omg-transaction/CreateBlockchainTransactionButton'
import {
  enableMetamaskEthereumConnection,
  getBlockchainBalanceByAddress
} from '../omg-web3/action'
import {
  selectMetamaskEnabled,
  selectCurrentAddress,
  selectBlockchainBalanceByAddressArray
} from '../omg-web3/selector'
import TopNavigation from '../omg-page-layout/TopNavigation'

const MetaMaskImage = styled.img`
  max-width: 250px;
  display: block;
  margin: 0 auto;
`
const SelectStateContainer = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  height: 100%;
  text-align: center;
`

const RowInfo = styled.div`
  margin-bottom: 10px;
`

const ConnectedStepContainer = styled.div``

const AccountBlanaceTitle = styled.h4`
  display: inline-block;
`
function BlockchainConnect () {
  const dispatch = useDispatch()
  const metamaskEnabled = useSelector(selectMetamaskEnabled)
  const selectedAddress = useSelector(selectCurrentAddress)
  const balance = useSelector(selectBlockchainBalanceByAddressArray)(selectedAddress)
  const [networkType, setNetworkType] = useState('...')
  useEffect(() => {
    const { web3 } = window
    getBlockchainBalanceByAddress(selectedAddress)(dispatch)
    web3.eth.net.getNetworkType().then(setNetworkType)
  }, [selectedAddress, networkType])

  const onClickConnect = () => {
    enableMetamaskEthereumConnection()(dispatch)
  }

  const connectedStep = (
    <ConnectedStepContainer>
      <TopNavigation
        title={'Ethereum Connect'}
        searchBar={false}
        buttons={[
          <CreateBlockchainTransactionButton
            fromAddress={selectedAddress}
            key='create-blockchain-button'
          />
        ]}
      />
      <RowInfo>
        <h4>Address</h4>
        <span>{selectedAddress}</span>
      </RowInfo>
      <RowInfo>
        <h4>Network</h4>
        <span> {_.upperFirst(networkType)}</span>
      </RowInfo>
      <RowInfo>
        <div>
          <AccountBlanaceTitle>Account Balance</AccountBlanaceTitle>{' '}
          <a>add custom token</a>
        </div>
        {balance.length &&
          balance.map(token => {
            return (
              <span key={token.symbol}>
                {token.balance} {_.upperCase(token.token)}
              </span>
            )
          })}
      </RowInfo>
    </ConnectedStepContainer>
  )
  const selectStep = (
    <SelectStateContainer>
      <div>
        <MetaMaskImage src={require('../../statics/images/metamask.svg')} />
        <Button onClick={onClickConnect}>Connect metamask</Button>
      </div>
    </SelectStateContainer>
  )

  return metamaskEnabled ? connectedStep : selectStep
}

export default BlockchainConnect
