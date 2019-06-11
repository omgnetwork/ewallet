export const closeModal = ({ id, ...rest }) => dispatch => {
  return dispatch({ type: 'MODAL/CLOSE', data: { id, ...rest } })
}

export const openModal = ({ id, ...rest }) => (dispatch, getState) => {
  const modal = getState().modals[id]
  if (!modal) {
    console.warn(
      `attempt to open modal id [${id}] that does not exist, please add modal id in modalController`
    )
  }
  return dispatch({ type: 'MODAL/OPEN', data: { id, ...rest } })
}
