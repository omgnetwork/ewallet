export const selectGetModalById = state => id => {
  const modal = selectModals(state)[id]
  if (!modal) {
    console.warn(
      `attempt to open modal id [${id}] that does not exist, please add modal id in modalController`
    )
  }
}
export const selectModals = state => state.modals
