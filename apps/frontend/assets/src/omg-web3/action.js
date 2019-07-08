import Web3 from 'web3'
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
