import { createActionCreator } from '../utils/createActionCreator'
export const enableMetamaskEthereumConnection = () =>
  createActionCreator({
    actionName: 'METAMASK',
    action: 'CONNECT',
    service: async () => {
      const { ethereum } = window
      if (ethereum) {
        const connectResult = await ethereum.enable()
        if (connectResult) {
          return { data: connectResult, success: true }
        }
      }
    }
  })
