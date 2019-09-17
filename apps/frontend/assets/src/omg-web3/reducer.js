import createReducer from '../reducer/createReducer'
export const metamaskReducer = createReducer(
  {},
  {
    'METAMASK/ENABLE/SUCCESS': state => {
      return { ...state, enabled: true }
    },
    'METAMASK/SET_EXIST': (state, { data: exist }) => {
      return { ...state, exist }
    },
    'METAMASK/UPDATE_SETTINGS': (
      state,
      {
        data: {
          isUnlocked,
          isEnabled,
          networkVersion,
          onboardingcomplete,
          selectedAddress
        }
      }
    ) => {
      return {
        ...state,
        enabled: isEnabled,
        unlocked: isUnlocked,
        networkVersion,
        onboardingcomplete,
        selectedAddress
      }
    }
  }
)

export const blockchainBalanceReducer = createReducer(
  {},
  {
    'BLOCKCHAIN_BALANCE/REQUEST/SUCCESS': (state, { data }) => {
      return {
        ...state,
        [data.address]: { ...state[data.address], [data.token]: data }
      }
    }
  }
)
