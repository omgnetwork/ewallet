export const selectGetModalById = state => id => selectModals(state)[id]
export const selectModals = state => state.modals
