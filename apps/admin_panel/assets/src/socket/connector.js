import { Socket } from 'phoenix'
const socket = new Socket('/socket', { params: { userToken: '123' } })
socket.connect()
