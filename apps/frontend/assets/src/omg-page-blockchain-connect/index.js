import React, { useEffect, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import styled from 'styled-components'

import { Button } from '../omg-uikit'
import {
  enableMetamaskEthereumConnection,
  getBlockchainBalanceByAddress
} from '../omg-web3/action'
import {
  selectCurrentAddress,
  selectBlockchainBalanceByAddressArray,
  selectMetamaskUsable
} from '../omg-web3/selector'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { formatReceiveAmountToTotal } from '../utils/formatter'

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

const AccountBalanceTitle = styled.h4`
  display: inline-block;
`
function BlockchainConnect () {
  const dispatch = useDispatch()
  const selectedAddress = useSelector(selectCurrentAddress)
  const metamaskUsable = useSelector(selectMetamaskUsable)
  const balance = useSelector(selectBlockchainBalanceByAddressArray)(
    selectedAddress
  )
  const [networkType, setNetworkType] = useState('...')
  useEffect(() => {
    const { web3 } = window
    if (web3) {
      getBlockchainBalanceByAddress(selectedAddress)(dispatch)
      web3.eth.net.getNetworkType().then(setNetworkType)
    }
  }, [selectedAddress, networkType])

  const onClickConnect = () => {
    enableMetamaskEthereumConnection()(dispatch)
  }

  const connectedStep = (
    <ConnectedStepContainer>
      <TopNavigation
        title={'Ethereum Connect'}
        searchBar={false}
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
          <AccountBalanceTitle>Account Balance</AccountBalanceTitle>{' '}
          {/* <a>add custom token</a> */}
        </div>
        {balance.length &&
          balance.map(token => {
            return (
              <span key={token.token}>
                {formatReceiveAmountToTotal(token.balance, 10 ** token.decimal)}{' '}
                {_.upperCase(token.token)}
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
        <Button onClick={onClickConnect} disabled={!window.ethereum || !window.web3}>
          Connect metamask
        </Button>
      </div>
    </SelectStateContainer>
  )

  return metamaskUsable ? connectedStep : selectStep
}

export default BlockchainConnect
