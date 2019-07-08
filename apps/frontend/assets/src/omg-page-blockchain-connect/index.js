import React from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { Button } from '../omg-uikit'
import { enableMetamaskEthereumConnection } from '../omg-web3/action'
import { selectMetamaskConnectionStatus } from '../omg-web3/selector'
function BlockchainConnect () {
  const dispatch = useDispatch()
  const metamaskConnectionStatus = useSelector(selectMetamaskConnectionStatus)
  const onClickConnect = () => {
    enableMetamaskEthereumConnection()(dispatch)
  }
  return (
    <div>
      <Button onClick={onClickConnect}>Connect metamask</Button>
      <div>connected: {String(metamaskConnectionStatus)}</div>
    </div>
  )
}

export default BlockchainConnect
