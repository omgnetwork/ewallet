import { appendParams, isAbsoluteURL } from '../utils/url'
import urlJoin from 'url-join'
import _ from 'lodash'
import CONSTANT from '../constants'
import uuid from 'uuid/v4'
class SocketConnector {
  constructor (url, params = {}) {
    this.socket = null
    this.url = this.normalizeUrl(url)
    this.params = Object.assign(params, {
      heartbeatInterval: 5000,
      reconnectInterval: 5000
    })
    this.handleOnConnected = () => {}
    this.handleOnDisconnected = () => {}
    this.handleOnMessage = () => {}
    this.WebSocket = WebSocket
    this.connectionStateMap = {
      '0': 'CONNECTING',
      '1': 'CONNECTED',
      '2': 'DISCONNECTING',
      '3': 'DISCONNECTED'
    }
    this.queue = []
    this.joinedChannels = []
  }
  setParams (params) {
    this.params = Object.assign(this.params, params)
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
  onConnect = resolve => () => {
    console.log('websocket connected.')
    this.handleOnConnected()
    this.drainQueue()
    return resolve(true)
  }
  onDisconnect = () => {
    this.handleOnDisconnected()
    this.socket.removeEventListener('open', this.onConnect)
    this.socket.removeEventListener('close', this.onDisconnect)
    this.socket.removeEventListener('message', this.handleMessage)
    clearInterval(this.heartbeat)
    console.log('websocket disconnected.')
    this.addJoinedChannelToQueue()
    this.reconnect()
  }
  drainQueue = () => {
    this.queue.forEach(q => {
      this.send(q)
    })
  }
  addChannelToJoinedChannels = channel => {
    if (!this.channelExistInJoinedChannels(this.joinedChannels, channel)) {
      this.joinedChannels.push(channel)
    }
  }
  addChannelToQueue = channel => {
    if (!this.channelExistInQueue(this.queue, channel)) {
      this.queue.push(this.createJoinChannelPayload(channel))
    }
  }
  removeMessageFromQueue = msg => {
    this.queue = this.queue.filter(q => q.ref !== msg.ref)
  }
  removeChannelFromJoinedChannel = channel => {
    _.pull(this.joinedChannels, channel)
  }
  addJoinedChannelToQueue = () => {
    this.joinedChannels.forEach(channel => {
      this.addChannelToQueue(channel)
    })
    this.joinedChannels = []
  }
  channelExistInQueue (queue, channel) {
    return _.findIndex(queue, e => e.topic === channel) !== -1
  }
  channelExistInJoinedChannels (joinedChannels, channel) {
    return _.includes(joinedChannels, channel)
  }

  on (event, handler) {
    switch (event) {
      case 'connected':
        return (this.handleOnConnected = handler)
      case 'disconnected':
        return (this.handleOnDisconnected = handler)
      case 'message':
        return (this.handleOnMessage = handler)
    }
  }
  sendHeartbeatEvent = () => {
    const payload = this.createPayload({
      topic: CONSTANT.WEBSOCKET.HEARTBEAT_TOPIC,
      event: CONSTANT.WEBSOCKET.HEARTBEAT_EVENT
    })
    this.send(payload)
  }
  async reconnect () {
    setTimeout(async () => {
      console.log('reconnecting websocket...')
      await this.connect()
    }, this.params.reconnectInterval)
  }
  connect () {
    return new Promise((resolve, reject) => {
      const urlWithAuths = appendParams(this.url, this.params)
      this.socket = new this.WebSocket(urlWithAuths)
      this.socket.addEventListener('open', this.onConnect(resolve))
      this.socket.addEventListener('close', this.onDisconnect)
      this.socket.addEventListener('message', this.handleMessage)
      this.heartbeat = setInterval(this.sendHeartbeatEvent, this.params.heartbeatInterval)
    })
  }
  disconnect () {
    this.socket.close()
  }
  handleMessage = message => {
    const msg = JSON.parse(message.data)
    const ref = msg.ref
    const refType = ref.split(':')[0]
    if (msg.success) {
      switch (refType) {
        case CONSTANT.WEBSOCKET.JOIN_CHANNEL_REF:
          console.log('joined websocket channel:', msg.topic)
          this.addChannelToJoinedChannels(msg.topic)
          break
        case CONSTANT.WEBSOCKET.LEAVE_CHANNEL_REF:
          console.log('left websocket channel:', msg.topic)
          this.removeChannelFromJoinedChannel(msg.topic)
          break
      }
      this.removeMessageFromQueue(msg)
    } else {
      console.error('websocket event reply error with response', msg)
    }
    this.handleOnMessage(msg)
  }
  getConnectionStatus () {
    return this.connectionStateMap[this.socket.readyState]
  }

  joinChannel (channel) {
    const channelExistInQueue = this.channelExistInQueue(this.queue, channel)
    const channelIsJoined = this.channelExistInJoinedChannels(this.joinedChannels, channel)
    if (!channelExistInQueue && !channelIsJoined) {
      const payload = this.createJoinChannelPayload(channel)
      this.queue.push(payload)
      try {
        this.send(payload)
      } catch (error) {
        console.warn('something went wrong while joining channel with error', error)
      }
    }
  }
  leaveChannel = channel => {
    this.send(this.createLeaveChannelPayload(channel))
  }
  createPayload = ({ topic, event, type, data = {} }) => {
    const payload = {
      topic,
      event,
      ref: `${type}:${uuid()}`,
      data
    }
    return payload
  }
  send = payload => {
    this.socket.send(JSON.stringify(payload))
  }
  createJoinChannelPayload (channel) {
    return this.createPayload({
      topic: channel,
      type: CONSTANT.WEBSOCKET.JOIN_CHANNEL_REF,
      event: CONSTANT.WEBSOCKET.JOIN_CHANNEL_EVENT
    })
  }
  createLeaveChannelPayload (channel) {
    return this.createPayload({
      topic: channel,
      type: CONSTANT.WEBSOCKET.LEAVE_CHANNEL_REF,
      event: CONSTANT.WEBSOCKET.LEAVE_CHANNEL_EVENT
    })
  }
}
export default SocketConnector
