import React from 'react'
import { connect } from 'react-redux'
import { selectCurrentModal } from './selector'
import { closeModal, openModal } from './action'

import CreateTransactionModal from '../omg-create-transaction-modal'

const modals = [{ id: 'createTransaction', modal: CreateTransactionModal }]

function ModalController (props) {
  return modals.map(({ id, modal: Modal }) => {
    return (
      <Modal
        key={id}
        onRequestClose={props.closeModal}
        open={props.currentOpenModal.id === id}
        {...props.currentOpenModal}
      />
    )
  })
}

export default connect(
  state => ({ currentOpenModal: selectCurrentModal(state) }),
  { closeModal, openModal }
)(ModalController)
