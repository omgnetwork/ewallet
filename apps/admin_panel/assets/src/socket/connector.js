import { Socket } from 'phoenix'

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
  subscribe (topic, handler) {
    this.socket.channel(topic, msg => {
      handler(msg)
    })
  }
}
export default SocketConnector
