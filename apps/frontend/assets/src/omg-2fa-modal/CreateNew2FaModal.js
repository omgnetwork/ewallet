import React, { useEffect, useState } from 'react'
import { useDispatch } from 'react-redux'
import PropTypes from 'prop-types'
import Modal from '../omg-modal'
import { createSecretCodes } from '../omg-2fa/action'
import { QrCode } from '../omg-uikit'

function CreateTwoFaModal ({ open, onRequestClose }) {
  const dispatch = useDispatch()
  const [secretCode, setSecretCode] = useState(null)
  useEffect(() => {
    createSecretCodes()(dispatch).then(({ data }) => {
      if (data) setSecretCode(data.secret_2fa_code)
    })
  }, [])

  return (
    <Modal isOpen={open} onRequestClose={onRequestClose}>
      <div>please scan the QR</div>
      <QrCode data={secretCode} />
    </Modal>
  )
}

CreateTwoFaModal.propTypes = {
  open: PropTypes.bool,
  onRequestClose: PropTypes.func
}
export default CreateTwoFaModal
