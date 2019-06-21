import React, { useState } from 'react'
import _ from 'lodash'
import { useDispatch } from 'react-redux'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'

import Modal from '../omg-modal'
import {
  createSecretCodes,
  enable2Fa,
  createBackupCodes
} from '../omg-2fa/action'
import { to2FaFormat } from '../omg-2fa/serializer'
import { QrCode, Input, Button, Icon } from '../omg-uikit'

const Create2FaModalContainer = styled.div`
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
  input {
    text-align: center;
    font-size: 18px;
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

function CreateTwoFaModal ({ open, onRequestClose, history }) {
  const dispatch = useDispatch()
  const [secretCode, setSecretCode] = useState(null)
  const [backupCodes, setBackupCodes] = useState(null)
  const [passcode, setPasscode] = useState('')
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')

  const onEnable2Fa = async () => {
    const { data: backupCodeResult } = await createBackupCodes()(dispatch)
    if (backupCodeResult) {
      const { data: secretResult } = await enable2Fa(passcode)(dispatch)
      if (secretResult) {
        setBackupCodes(backupCodeResult)
        setSubmitStatus('SUCCESS')
      } else {
        setSubmitStatus('FAILED')
      }
    } else {
      setSubmitStatus('FAILED')
    }
  }
  const afterClose = () => {
    setPasscode('')
    setSecretCode(null)
    setBackupCodes('')
    setSubmitStatus('DEFAULT')
  }
  const onAfterOpen = () => {
    createSecretCodes()(dispatch).then(({ data }) => {
      if (data) setSecretCode(data)
    })
  }

  const onSubmit = e => {
    e.preventDefault()
    setSubmitStatus('LOADING')
    onEnable2Fa()
  }

  const onOkBackupCode = () => {
    onRequestClose()
    history.push('/login')
  }

  const onRequestCloseCheckBackup = () => {
    if (!backupCodes) onRequestClose()
  }

  const renderCreateMode = () => {
    return (
      <form onSubmit={onSubmit}>
        <h4>Please scan the QR</h4>
        <div>
          Secret code: {_.get(secretCode, 'secret_2fa_code', 'loading code..')}
        </div>
        <QrCode data={secretCode && to2FaFormat(secretCode)} size={200} />
        <Input
          value={passcode}
          onChange={e => setPasscode(e.target.value)}
          normalPlaceholder='2fa token...'
          maxLength={6}
        />
        <Button loading={submitStatus === 'LOADING'}>
          Enable Two Factor Authentication
        </Button>
      </form>
    )
  }

  const renderShowBackup = () => {
    return (
      <div className='backup-container'>
        <h4>Please keep your backup codes</h4>
        <p>
          Please print or download these one-time use backup codes for times when your device is unavailable.
        </p>
        {backupCodes.backup_codes.map(backupCode => {
          return (
            <div key={backupCode} className='backup-item'>
              {backupCode}
            </div>
          )
        })}
        <div>
          <Button onClick={onOkBackupCode}>
            {'Ok, I\'ve saved the backup codes'}
            <br /> ( This will log you out )
          </Button>
        </div>
      </div>
    )
  }
  return (
    <Modal
      isOpen={open}
      onRequestClose={onRequestCloseCheckBackup}
      onAfterClose={afterClose}
      onAfterOpen={onAfterOpen}
    >
      <Create2FaModalContainer>
        {!backupCodes && <Icon name='Close' onClick={onRequestClose} />}
        {backupCodes ? renderShowBackup() : renderCreateMode()}
      </Create2FaModalContainer>
    </Modal>
  )
}

CreateTwoFaModal.propTypes = {
  open: PropTypes.bool,
  onRequestClose: PropTypes.func,
  history: PropTypes.object
}
export default withRouter(CreateTwoFaModal)
