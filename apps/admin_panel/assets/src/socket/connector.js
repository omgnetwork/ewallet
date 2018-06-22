import { Socket } from './phoenix'

class SocketConnector {
  constructor (params = {}) {
    this.socket = new Socket('ws://localhost:4000/api/admin/socket', { params })
    this.connected = false
  }
  connect () {
    try {
      this.socket.connect()
      this.connected = true
    } catch (error) {
      console.log('Cannot connect to web socket with error', error)
    }
  }
  disconnect () {
    this.socket.disconnect()
  }
  getConnectionStatus () {
    return this.connected
  }
  subscribe (channelToSubscribe, topics = [], handler = () => {}) {
    const channel = this.socket.channel(channelToSubscribe)
    topics.forEach(topic => {
      channel.on(topic, handler)
    })
    channel
      .join()
      .receive('ok', ({ messages }) => console.log('joined channel:', channelToSubscribe, messages))
      .receive('error', ({ reason }) =>
        console.log('failed to join channel:', channelToSubscribe, reason)
      )
      .receive('timeout', () => console.log('Networking issue. Still waiting...'))
  }
}
export default SocketConnector
