import Socket from 'phoenix-socket'
const socket = new Socket('wss://localhost:4000/api/socket', { params: { userToken: '123' } })
socket.connect()
