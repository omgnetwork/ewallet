import _ from 'lodash'

export const selectConfigurationById = state => configurationId => {
  return state.configurations[configurationId] || {}
}

export const selectInternalEnabled = () => state => {
  return state.configurations.internal_enabled?.value !== 'boolean'
    ? state.configurations.internal_enabled?.value
    : true
}

export const selectConfigurations = state => {
  return state.configurations || {}
}

export const selectConfigurationsByKey = state => {
  return _.keyBy(selectConfigurations(state), 'key')
}

export const selectConfigurationLoadingStatus = state => state.loadingStatus.configurations

export const selectConfigurationUpdateLoadingStatus = state => state.loadingStatus.configurationsUpdate
