import React from 'react'
import { useDispatch } from 'react-redux'
import { Button } from '../omg-uikit'
import { enableMetamaskEthereumConnection } from '../omg-web3/action'
function BlockchainConnect () {
  const dispatch = useDispatch()
  const onClickConnect = () => {
    enableMetamaskEthereumConnection()(dispatch)
  }
  return (
    <div>
      <Button onClick={onClickConnect}>Connect metamask</Button>
    </div>
  )
}

export default BlockchainConnect
