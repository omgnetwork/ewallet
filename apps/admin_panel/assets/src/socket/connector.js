import { appendParams, isAbsoluteURL } from '../utils/urlBuilder'
import urlJoin from 'url-join'
class SocketConnector {
  constructor (url, params = {}) {
    this.socket = null
    this.url = this.normalizeUrl(url)
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
    this.joinedChannel = {}
  }
  setParams (params) {
    this.params = params
  }
  normalizeUrl (url) {
    let normalizedUrl = ''
    if (!isAbsoluteURL(url)) {
      const origin =
        window.location.protocol +
        '//' +
        window.location.hostname +
        (window.location.port ? ':' + window.location.port : '')
      normalizedUrl = urlJoin(origin, url)
    } else {
      normalizedUrl = url
    }
    return normalizedUrl.replace('http://', 'ws://').replace('https://', 'wss://')
  }
  open = resolve => () => {
    console.log('websocket connected.')
    this.handleOnConnected()
    resolve(true)
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
    return new Promise((resolve, reject) => {
      const urlWithAuths = appendParams(this.url, this.params)
      this.socket = new WebSocket(urlWithAuths)
      this.socket.addEventListener('open', this.open(resolve))
      this.socket.addEventListener('close', this.close)
      this.socket.addEventListener('message', this.handleBackendMessage)
      setInterval(this.heartbeat, this.params.heartbeatInterval || 5000)
    })
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
      console.log('joined websocket channel:', parsedMessage.topic)
    }
    return parsedMessage
  }
  getConnectionStatus () {
    return this.connectionStateMap[this.socket.readyState]
  }
  joinChannel (channel) {
    if (!this.joinedChannel[channel]) {
      const payload = JSON.stringify({
        topic: channel,
        event: 'phx_join',
        ref: '1',
        data: {}
      })
      this.socket.send(payload)
    }
    this.joinedChannel[channel] = true
  }
  leaveChannel (channel) {
    const payload = JSON.stringify({
      topic: channel,
      event: 'phx_leave',
      ref: '1',
      data: {}
    })
    this.socket.send(payload)
    delete this.joinedChannel[channel]
  }
}
export default SocketConnector
