import createReducer from '../reducer/createReducer'
export const currentUserReducer = createReducer(
  {},
  {
    'SESSION/LOGIN/SUCCESS': (state, { data }) => {
      return data.user
    },
    'CURRENT_USER/REQUEST/SUCCESS': (state, { data }) => {
      return data
    },
    'CURRENT_USER/UPDATE/SUCCESS': (state, { data }) => {
      return data
    },
    'CURRENT_USER_EMAIL/UPDATE/SUCCESS': (state, { data }) => {
      return data
    },
    '2FA/ENABLE/SUCCESS': state => {
      return { ...state, enabled_2fa_at: true }
    },
    '2FA/DISABLE/SUCCESS': state => {
      return { ...state, enabled_2fa_at: false }
    }
  }
)

export const currentUserLoadingStatusReducer = createReducer('DEFAULT', {
  'CURRENT_USER/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'CURRENT_USER/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CURRENT_USER/REQUEST/FAILED': (state, action) => 'FAILED'
})
