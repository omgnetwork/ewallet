import React, { useState } from 'react'
import _ from 'lodash'
import { useDispatch } from 'react-redux'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import Modal from '../omg-modal'
import { createSecretCodes, enable2Fa } from '../omg-2fa/action'
import { to2FaFormat } from '../omg-2fa/serializer'
import { QrCode, Input, Button } from '../omg-uikit'

const Create2FaModalContainer = styled.div`
  padding: 20px;
  text-align: center;
  width: 350px;
  button {
    margin-top: 20px;
  }
  h4 {
    margin-bottom: 10px;
  }
`

function CreateTwoFaModal ({ open, onRequestClose }) {
  const dispatch = useDispatch()
  const [secretCode, setSecretCode] = useState(null)
  const [passcode, setPasscode] = useState('')
  const onEnable2Fa = () => {
    enable2Fa(passcode)(dispatch)
  }
  const afterClose = () => {
    setPasscode('')
    setSecretCode(null)
  }
  const onAfterOpen = () => {
    createSecretCodes()(dispatch).then(({ data }) => {
      if (data) setSecretCode(data)
    })
  }

  return (
    <Modal
      isOpen={open}
      onRequestClose={onRequestClose}
      onAfterClose={afterClose}
      onAfterOpen={onAfterOpen}
    >
      <Create2FaModalContainer>
        <h4>please scan the QR</h4>
        <div>Secret code: {_.get(secretCode, 'secret_2fa_code', 'loading code..')}</div>
        <QrCode data={secretCode && to2FaFormat(secretCode)} size={200} />
        <Input
          value={passcode}
          onChange={e => setPasscode(e.target.value)}
          normalPlaceholder='passcode...'
        />
        <Button onClick={onEnable2Fa}>Enable 2Factor Authnetication</Button>
      </Create2FaModalContainer>
    </Modal>
  )
}

CreateTwoFaModal.propTypes = {
  open: PropTypes.bool,
  onRequestClose: PropTypes.func
}
export default CreateTwoFaModal
