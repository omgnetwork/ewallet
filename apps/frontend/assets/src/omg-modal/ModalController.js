import React from 'react'
import { connect } from 'react-redux'
import { selectGetModalById } from './selector'
import { closeModal, openModal } from './action'

import CreateTransactionModal from '../omg-create-transaction-modal'
import Enable2FaModal from '../omg-2fa-modal/Enable2FaModal'
import Enter2FaModal from '../omg-2fa-modal/Enter2FaModal'
import Disable2FaModal from '../omg-2fa-modal/Disable2FaModal'
// ADD YOUR NEW MODAL HERE
const modals = [
  { id: 'createTransaction', modal: CreateTransactionModal },
  { id: 'enable2FaModal', modal: Enable2FaModal },
  { id: 'enter2FaModal', modal: Enter2FaModal },
  { id: 'disable2FaModal', modal: Disable2FaModal }
]

function ModalController (props) {
  return modals.map(({ id, modal: Modal }) => {
    const modal = props.selectModalById(id) || {}
    return (
      <Modal
        key={id}
        onRequestClose={() => props.closeModal({ id })}
        {...modal}
      />
    )
  })
}

export default connect(
  state => ({ selectModalById: selectGetModalById(state) }),
  { closeModal, openModal }
)(ModalController)
