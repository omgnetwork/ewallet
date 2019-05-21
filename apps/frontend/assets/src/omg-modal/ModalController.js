import React from 'react'
import { connect } from 'react-redux'
import { selectGetModalById } from './selector'
import { closeModal, openModal } from './action'

import CreateTransactionModal from '../omg-create-transaction-modal'
import _ from 'lodash'

// ADD YOUR NEW MODAL HERE
const modals = [
  { id: 'createTransaction', modal: CreateTransactionModal }
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
