export const closeModal = ({ id, ...rest }) => dispatch => {
  dispatch({ type: 'MODAL/CLOSE', data: { id, ...rest } })
}

export const openModal = ({ id, ...rest }) => dispatch => {
  dispatch({ type: 'MODAL/OPEN', data: { id, ...rest } })
}
