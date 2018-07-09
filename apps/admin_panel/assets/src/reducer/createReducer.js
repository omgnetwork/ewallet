const createReducer = (initialState, actions) => (state = initialState, action) => {
  console.log(state, action)
  return actions[action.type] ? actions[action.type](state, action) : state
}

export default createReducer
