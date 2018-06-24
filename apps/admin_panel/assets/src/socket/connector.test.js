import SocketConnector from './connector'
describe('websocket', () => {
  const socket = new SocketConnector()
  class MockWebSocket {
    constructor () {
      this.events = {}
    }
    fakeEventListenerCallbackCall = event => {
      if (event === 'open') {
        this.readyState = '1'
      }
      if (event === 'close') {
        this.readyState = '3'
      }
      this.events[event]()
    }
    addEventListener = jest.fn((event, cb) => {
      this.events[event] = cb
    })
    removeEventListener = jest.fn()
    readyState = '1'
    send = jest.fn()
  }
  socket.WebSocket = MockWebSocket
  afterEach(() => {
    socket.queueJoinChannels = []
    socket.joinedChannels = []
  })
  test('connect should return true if websocket is connected', async () => {
    let result = socket.connect().then(result => {
      expect(result).toBe(true)
    })
    socket.socket.fakeEventListenerCallbackCall('open')
    return result
  })
  test('should get connection status correctly when connected', () => {
    let result = socket.connect().then(result => {
      expect(result).toBe(true)
      expect(socket.getConnectionStatus()).toBe('CONNECTED')
      socket.socket.fakeEventListenerCallbackCall('close')
      expect(socket.getConnectionStatus()).toBe('DISCONNECTED')
    })
    socket.socket.fakeEventListenerCallbackCall('open')
    return result
  })
  test('should reconnect when disconnected', () => {
    socket.reconnect = jest.fn()
    let result = socket.connect().then(result => {
      socket.socket.fakeEventListenerCallbackCall('close')
      expect(socket.socket).toBe(null)
      expect(socket.reconnect).toBeCalled()
    })
    socket.socket.fakeEventListenerCallbackCall('open')
    return result
  })
  test('should be able to send join event if socket is connected', () => {
    let result = socket.connect().then(result => {
      expect(result).toBe(true)
      socket.joinChannel('test_channel')
      expect(socket.socket.send).toBeCalledWith(
        JSON.stringify({
          topic: 'test_channel',
          event: 'phx_join',
          ref: '1',
          data: {}
        })
      )
      expect(socket.queueJoinChannels.length === 1)
    })
    socket.socket.fakeEventListenerCallbackCall('open')
    return result
  })
  test('should send leave event correctly', () => {
    let result = socket.connect().then(result => {
      expect(result).toBe(true)
      socket.leaveChannel('test_channel')
      expect(socket.socket.send).toBeCalledWith(
        JSON.stringify({
          topic: 'test_channel',
          event: 'phx_leave',
          ref: '2',
          data: {}
        })
      )
    })
    socket.socket.fakeEventListenerCallbackCall('open')
    return result
  })
  test('should send heartbeat event correctly', () => {
    let result = socket.connect().then(result => {
      expect(result).toBe(true)
      socket.sendHeartbeatEvent()
      expect(socket.socket.send).toBeCalledWith(
         JSON.stringify({
           topic: 'phoenix',
           event: 'heartbeat',
           ref: '1',
           data: {}
         })
      )
    })
    socket.socket.fakeEventListenerCallbackCall('open')
    return result
  })
})
