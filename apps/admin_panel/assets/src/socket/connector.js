function serialize (obj, parentKey) {
  let queryStr = []
  for (var key in obj) {
    if (!obj.hasOwnProperty(key)) {
      continue
    }
    let paramKey = parentKey ? `${parentKey}[${key}]` : key
    let paramVal = obj[key]
    if (typeof paramVal === 'object') {
      queryStr.push(serialize(paramVal, paramKey))
    } else {
      queryStr.push(encodeURIComponent(paramKey) + '=' + encodeURIComponent(paramVal))
    }
  }
  return queryStr.join('&')
}

function appendParams (url, params) {
  if (Object.keys(params).length === 0) {
    return url
  }

  let prefix = url.match(/\?/) ? '&' : '?'
  return `${url}${prefix}${serialize(params)}`
}
class SocketConnector {
  constructor (params = {}) {
    this.socket = null
    this.url = 'ws://localhost:4000/api/admin/socket'
    this.params = params
    this.connected = false
  }
  connect () {
    this.socket = new WebSocket(appendParams(this.url, this.socket))
    this.socket.addEventListener('open', function (event) {
      this.connected = true
      console.log('connected websocket url:', this.url)
    })
    this.socket.addEventListener('close', function (event) {
      this.connected = false
      console.log('disconnected websocket url:', this.url)
    })
  }
  disconnect () {
    this.socket.close()
  }
  getConnectionStatus () {
    return this.connected
  }
  subscribe (channelToSubscribe, topics = [], handler = () => {}) {
    // const channel = this.socket.channel(channelToSubscribe)
    // topics.forEach(topic => {
    //   channel.on(topic, handler)
    // })
    // channel
    //   .join()
    //   .receive('ok', () => console.log('joined channel:', channelToSubscribe))
    //   .receive('error', () => console.log('failed to join channel:', channelToSubscribe))
    //   .receive('timeout', () => console.log('Networking issue. Still waiting...'))
  }
}
export default SocketConnector
