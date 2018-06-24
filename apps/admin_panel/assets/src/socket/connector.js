import { appendParams, isAbsoluteURL } from '../utils/url'
import urlJoin from 'url-join'
import _ from 'lodash'
class SocketConnector {
  constructor (url, params = {}) {
    this.socket = null
    this.url = this.normalizeUrl(url)
    this.params = params
    this.handleOnConnected = () => {}
    this.handleOnDisconnected = () => {}
    this.WebSocket = WebSocket
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
  open = (resolve) => () => {
    console.log('websocket connected.')
    this.handleOnConnected()
    this.drainQueue()
    return resolve(true)
  }
  drainQueue = () => {
    if (this.queueJoinChannels.length > 0) {
      this.queueJoinChannels.forEach(channel => {
        this.sendJoinEvent(channel)
      })
    }
  }
  addJoinedChannelToQueue = () => {
    if (this.joinedChannels.length > 0) {
      this.joinedChannels.forEach(channel => {
        if (!_.includes(this.queueJoinChannels, channel)) {
          this.queueJoinChannels.push(channel)
        }
      })
      this.joinedChannels = []
    }
  }
  close = () => {
    this.handleOnDisconnected()
    this.socket.removeEventListener('open', this.open)
    this.socket.removeEventListener('close', this.close)
    this.socket.removeEventListener('message', this.handleMessage)
    this.socket = null
    clearInterval(this.heartbeat)
    console.log('websocket disconnected.')
    this.addJoinedChannelToQueue()
    this.reconnect()
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
  async reconnect () {
    setTimeout(async () => {
      console.log('reconnecting websocket...')
      await this.connect()
    }, 5000)
  }
  connect () {
    return new Promise((resolve, reject) => {
      const urlWithAuths = appendParams(this.url, this.params)
      this.socket = new this.WebSocket(urlWithAuths)
      this.socket.addEventListener('open', this.open(resolve))
      this.socket.addEventListener('close', this.close)
      this.socket.addEventListener('message', this.handleMessage)
      this.heartbeat = setInterval(this.sendHeartbeatEvent, this.params.heartbeatInterval || 5000)
    })
  }
  disconnect () {
    this.socket.close()
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
        if (!_.includes(this.joinedChannels, parsedMessage.topic)) {
          this.joinedChannels.push(parsedMessage.topic)
        }
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
    if (!_.includes(this.queueJoinChannels, channel) && !_.includes(this.joinedChannels, channel)) {
      this.queueJoinChannels.push(channel)
      this.sendJoinEvent(channel)
    }
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
