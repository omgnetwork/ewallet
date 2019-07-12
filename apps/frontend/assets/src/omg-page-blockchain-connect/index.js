import React, { useEffect, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import styled from 'styled-components'

import { Button } from '../omg-uikit'
import CreateBlockchainTransactionButton from '../omg-transaction/CreateBlockchainTransactionButton'
import { enableMetamaskEthereumConnection } from '../omg-web3/action'
import {
  selectMetamaskEnabled,
  selectCurrentAddress
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

const ConnectedStepContainer = styled.div``

function BlockchainConnect () {
  const dispatch = useDispatch()
  const metamaskEnabled = useSelector(selectMetamaskEnabled)
  const selectedAddress = useSelector(selectCurrentAddress)
  const [balance, setBalance] = useState('...')

  useEffect(() => {
    window.web3.eth.getBalance(selectedAddress).then(rawBalance => {
      const ethBalance = window.web3.utils.fromWei(rawBalance, 'ether')
      setBalance(ethBalance)
    })
  }, [selectedAddress])

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
      <div>
        <h4>Address</h4>
        <span>{selectedAddress}</span>
      </div>
      <div>
        <h4>Account Balance</h4>
        <span> {balance} ETH</span>
      </div>
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
