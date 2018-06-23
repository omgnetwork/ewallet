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
    this.queueJoinChannels = []
    this.joinedChannels = []
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
    if (this.queueJoinChannels.length > 0) {
      this.queueJoinChannels.forEach(channel => {
        this.sendJoinEvent(channel)
      })
    }
    return resolve(true)
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
  sendHeartbeatEvent = () => {
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
      this.socket.addEventListener('message', this.handleMessage)
      setInterval(this.sendHeartbeatEvent, this.params.heartbeatInterval || 5000)
    })
  }
  disconnect () {
    this.socket.close()
    this.socket.removeEventListener('open', this.open)
    this.socket.removeEventListener('close', this.close)
    this.socket.removeEventListener('message', this.handleMessage)
    clearInterval(this.sendHeartbeatEvent)
    this.handleOnDisconnected()
  }
  isJoinEvent (message) {
    return message.ref === '1' && message.topic !== 'phoenix'
  }
  isLeaveEvent (message) {
    return message.ref === '2' && message.event !== 'phoenix'
  }
  handleMessage = message => {
    const parsedMessage = JSON.parse(message.data)
    if (parsedMessage.success) {
      if (this.isJoinEvent(parsedMessage)) {
        console.log('joined websocket channel:', parsedMessage.topic)
        _.pull(this.queueJoinChannels, parsedMessage.topic)
        this.joinedChannels.push(parsedMessage.topic)
      } else if (this.isLeaveEvent(parsedMessage)) {
        console.log('left websocket channel:', parsedMessage.topic)
        _.pull(this.joinedChannels, parsedMessage.topic)
        _.pull(this.queueJoinChannels, parsedMessage.topic)
      } else {
        // OTHER EVENT
      }
    } else {
      console.error('websocket event reply error with response', parsedMessage)
    }
  }
  getConnectionStatus () {
    return this.connectionStateMap[this.socket.readyState]
  }
  sendJoinEvent (channel) {
    if (this.socket) {
      const payload = JSON.stringify({
        topic: channel,
        event: 'phx_join',
        ref: '1',
        data: {}
      })
      this.socket.send(payload)
    } else {
      console.warn('attempt to send an event while socket is not connected.')
    }
  }
  joinChannel (channel) {
    if (!_.includes(this.queueJoinChannels, channel)) {
      this.queueJoinChannels.push(channel)
    }
    this.sendJoinEvent(channel)
  }
  leaveChannel (channel) {
    const payload = JSON.stringify({
      topic: channel,
      event: 'phx_leave',
      ref: '2',
      data: {}
    })
    this.socket.send(payload)
  }
}
export default SocketConnector
