export const closeModal = id => dispatch => {
  dispatch({ type: 'MODAL/CLOSE', data: { id } })
}

export const openModal = id => dispatch => {
  dispatch({ type: 'MODAL/OPEN', data: { id } })
}
