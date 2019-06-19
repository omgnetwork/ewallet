import React, { useState } from 'react'
import { useDispatch } from 'react-redux'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import Modal from '../omg-modal'
import { disable2Fa } from '../omg-2fa/action'
import { Input, Button, Icon } from '../omg-uikit'

const Disable2FaModalContainer = styled.div`
  padding: 40px;
  text-align: center;
  width: 400px;
  position: relative;
  i {
    position: absolute;
    top: 15px;
    right: 15px;
    cursor: pointer;
  }
  button {
    margin-top: 20px;
  }
  h4 {
    margin-bottom: 10px;
  }
  .backup-container {
    text-align: center;
    p {
      margin: 20px 0;
    }
  }
  .backup-item {
    padding: 5px;
    display: inline-block;
    width: 110px;
  }
`

function DisableTwoFaModal ({ open, onRequestClose }) {
  const dispatch = useDispatch()
  const [passcode, setPasscode] = useState('')
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')

  const afterClose = () => {
    setPasscode('')
    setSubmitStatus('DEFAULT')
  }

  const onSubmit = async e => {
    e.preventDefault()
    setSubmitStatus('LOADING')
    const { data } = await disable2Fa(passcode)(dispatch)
    if (data) {
      setSubmitStatus('SUCCESS')
    }
  }

  const renderDisableSection = () => {
    return (
      <form onSubmit={onSubmit}>
        <h4>Disable 2Fa</h4>
        <Input
          value={passcode}
          onChange={e => setPasscode(e.target.value)}
          normalPlaceholder='passcode...'
        />
        <Button loading={submitStatus === 'LOADING'}>
          Disable 2Factor Authentication
        </Button>
      </form>
    )
  }

  return (
    <Modal
      isOpen={open}
      onRequestClose={onRequestClose}
      onAfterClose={afterClose}
    >
      <Disable2FaModalContainer>
        <Icon name='Close' onClick={onRequestClose} />
        {renderDisableSection()}
      </Disable2FaModalContainer>
    </Modal>
  )
}

DisableTwoFaModal.propTypes = {
  open: PropTypes.bool,
  onRequestClose: PropTypes.func
}
export default DisableTwoFaModal
