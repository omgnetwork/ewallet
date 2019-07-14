import { createActionCreator } from '../utils/createActionCreator'

const serializeDataFormat = ({ data, success }) => {
  return { data: { data: data, success } }
}
export const enableMetamaskEthereumConnection = () =>
  createActionCreator({
    actionName: 'METAMASK',
    action: 'ENABLE',
    service: async () => {
      const { ethereum } = window
      if (ethereum) {
        const connectResult = await ethereum.enable()
        if (connectResult.length) {
          return serializeDataFormat({ data: connectResult, success: true })
        }
      }
    }
  })

export const checkMetamaskExistance = (exist = false) => dispatch => {
  return dispatch({ type: 'METAMASK/SET_EXIST', data: { exist } })
}

export const setMetamaskSettings = metamaskSettings => dispatch => {
  return dispatch({ type: 'METAMASK/UPDATE_SETTINGS', data: metamaskSettings })
}

const createWeb3Call = fn => {
  if (!window.web3) {
    throw new Error('web3 metamask is not existed')
  }
  return fn
}
export const getBlockchainBalanceByAddress = createWeb3Call(
  address => async dispatch => {
    const { web3 } = window
    const rawBalance = await web3.eth.getBalance(address)
    return dispatch({
      type: 'BLOCKCHAIN_BALANCE/REQUEST/SUCCESS',
      data: { token: 'ETH', balance: rawBalance, address, decimal: 18 }
    })
  }
)

export const estimateGasFromTransaction = createWeb3Call(
  transaction => async dispatch => {
    const { web3 } = window
    const gas = await web3.eth.esimateGas(transaction)
    return dispatch({
      type: 'WEB3/ESTIMATE_GAS/SUCCESS',
      data: { transaction, gas }
    })
  }
)

export const getNetworkType = createWeb3Call(() => async dispatch => {
  const { web3 } = window
  const networkType = await web3.eth.net.getNetworkType
  return dispatch({
    type: 'WEB3/ESTIMATE_GAS/SUCCESS',
    data: { networkType }
  })
})

export const sendTransaction = createWeb3Call(
  ({
    transaction,
    onTransactionHash,
    onReceipt,
    onConfirmation,
    onError
  }) => async dispatch => {
    const { web3 } = window
    web3.eth
      .sendTransaction(transaction)
      .on('transactionHash', hash => {
        dispatch({
          type: 'WEB3/SEND_TRANSACTION/SUCCESS',
          data: { txHash: hash }
        })
        onTransactionHash(hash)
      })
      .on('receipt', onReceipt)
      .on('confirmation', onConfirmation)
      .on('error', onError)
  }
)
