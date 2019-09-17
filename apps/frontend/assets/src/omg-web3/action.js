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

const createWeb3Call = fn => dispatch => {
  if (!window.web3) {
    console.warn('web3 metamask is not existed')
  }
  return fn(dispatch)
}

export const getBlockchainBalanceByAddress = address =>
  createWeb3Call(async dispatch => {
    const { web3 } = window
    const rawBalance = await web3.eth.getBalance(address)
    return dispatch({
      type: 'BLOCKCHAIN_BALANCE/REQUEST/SUCCESS',
      data: { token: 'ETH', balance: rawBalance, address, decimal: 18 }
    })
  })

export const estimateGasFromTransaction = transaction =>
  createWeb3Call(async dispatch => {
    const { web3 } = window
    const gas = await web3.eth.estimateGas(transaction)
    return dispatch({
      type: 'WEB3/ESTIMATE_GAS/SUCCESS',
      data: { transaction, gas }
    })
  })

export const getNetworkType = () =>
  createWeb3Call(async dispatch => {
    const { web3 } = window
    const networkType = await web3.eth.net.getNetworkType
    return dispatch({
      type: 'WEB3/ESTIMATE_GAS/SUCCESS',
      data: { networkType }
    })
  })

export const sendErc20Transaction = ({
  transaction,
  onTransactionHash,
  onReceipt,
  onConfirmation,
  onError
}) =>
  createWeb3Call(async dispatch => {
    const { web3 } = window
    const { tokenAddress, to, from, value, gasPrice, gas } = transaction
    const minABI = [
      {
        'constant': false,
        'inputs': [
          {
            'name': '_to',
            'type': 'address'
          },
          {
            'name': '_value',
            'type': 'uint256'
          }
        ],
        'name': 'transfer',
        'outputs': [
          {
            'name': '',
            'type': 'bool'
          }
        ],
        'type': 'function'
      }
    ]
    const contract = new web3.eth.Contract(minABI, tokenAddress, { gasPrice, gas })
    try {
      contract.methods
        .transfer(to, value)
        .send({ from })
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
    } catch (e) {
      onError(e.message)
    }
  })

export const sendTransaction = ({
  transaction,
  onTransactionHash,
  onReceipt,
  onConfirmation,
  onError
}) =>
  createWeb3Call(async dispatch => {
    const { web3 } = window
    try {
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
    } catch (e) {
      onError(e.message)
    }
  })
