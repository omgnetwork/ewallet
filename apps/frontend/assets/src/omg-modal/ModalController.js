import React from 'react'
import { connect } from 'react-redux'
import { selectGetModalById } from './selector'
import { closeModal, openModal } from './action'

import CreateTransactionModal from '../omg-create-transaction-modal'
import Create2FaModal from '../omg-2fa-modal/CreateNew2FaModal'
// ADD YOUR NEW MODAL HERE
const modals = [
  { id: 'createTransaction', modal: CreateTransactionModal },
  { id: 'create2faModal', modal: Create2FaModal }
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
