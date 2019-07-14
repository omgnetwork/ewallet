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

export const getBlockchainBalanceByAddress = address => async dispatch => {
  const { web3 } = window
  if (web3) {
    const rawBalance = await web3.eth.getBalance(address)
    const ethBalance = web3.utils.fromWei(rawBalance, 'ether')
    return dispatch({
      type: 'BLOCKCHAIN_BALANCE/REQUEST/SUCCESS',
      data: { token: 'ETH', balance: ethBalance, address }
    })
  } else {
    throw new Error('web3 is not existed')
  }
}
