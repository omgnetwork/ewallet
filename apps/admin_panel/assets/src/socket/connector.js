import { appendParams } from '../utils/urlBuilder'
class SocketConnector {
  constructor (params = {}) {
    this.socket = null
    this.url = 'ws://localhost:4000/api/admin/socket'
    this.params = params
    this.connected = false
    this.handleOnConnected = () => {}
    this.handleOnDisconnected = () => {}
    this.connectionStateMap = {
      '0': 'CONNECTING',
      '1': 'CONNECTED',
      '2': 'DISCONNECTING',
      '3': 'DISCONNECTED'
    }
  }
  open = () => {
    console.log('websocket connected.')
    this.handleOnConnected()
  }
  close = () => {
    this.handleOnDisconnected()
    console.log('websocket disconnected.')
  }
  on (event, handler) {
    switch (event) {
      case 'connected':
        return (this.handleOnConnected = handler)
      case 'disconnected':
        return (this.handleOnDisconnected = handler)
    }
  }
  heartbeat = () => {
    const payload = JSON.stringify({
      topic: 'phoenix',
      event: 'heartbeat',
      ref: '1',
      data: {}
    })
    this.socket.send(payload)
  }
  connect () {
    const urlWithAuths = appendParams(this.url, this.params)
    this.socket = new WebSocket(urlWithAuths)
    this.socket.addEventListener('open', this.open)
    this.socket.addEventListener('close', this.close)
    this.socket.addEventListener('message', this.handleBackendMessage)
    setInterval(this.heartbeat, this.params.heartbeatInterval || 5000)
  }
  disconnect () {
    this.socket.close()
    this.socket.removeEventListener('open', this.open)
    this.socket.removeEventListener('close', this.close)
    this.socket.removeEventListener('message', this.handleBackendMessage)
    clearInterval(this.heartbeat)
    this.handleOnDisconnected()
  }
  handleBackendMessage (message) {
    const parsedMessage = JSON.parse(message.data)
    if (parsedMessage.event === 'phx_reply' && parsedMessage.topic !== 'phoenix') {
      console.log('joined channel:', parsedMessage.topic)
    }
    return parsedMessage
  }
  getConnectionStatus () {
    return this.connectionStateMap[this.socket.readyState]
  }
  joinChannel (channel) {
    const payload = JSON.stringify({
      topic: channel,
      event: 'phx_join',
      ref: '1',
      data: {}
    })
    this.socket.send(payload)
  }
  leaveChannel (channel) {
    const payload = JSON.stringify({
      topic: channel,
      event: 'phx_leave',
      ref: '1',
      data: {}
    })
    this.socket.send(payload)
  }
}
export default SocketConnector
