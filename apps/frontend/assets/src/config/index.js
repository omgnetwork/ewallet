import env from '@beam-australia/react-env'

export const ADMIN_API_URL = env('BACKEND_API_URL') || '/api/admin'
export const CLIENT_API_URL = env('CLIENT_API_URL') || '/api/client'
export const WEBSOCKET_URL = env('BACKEND_WEBSOCKET_URL') || '/api/admin/socket'

