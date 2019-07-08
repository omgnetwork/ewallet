import { createActionCreator } from '../utils/createActionCreator'

const serializeDataFormat = ({ data, success }) => {
  return { data: { data: data, success } }
}
export const enableMetamaskEthereumConnection = () =>
  createActionCreator({
    actionName: 'METAMASK',
    action: 'CONNECT',
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
