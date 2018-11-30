export const loadingStatusReducer = (state = {}, action) => {
  const { type } = action
  const matches = /(.*)\/(REQUEST)\/(INITIATED|SUCCESS|FAILED)/.exec(type)
  if (!matches) return state
  return {
    ...state,
    [_.camelCase(matches[1])]: matches[3]
  }
}
