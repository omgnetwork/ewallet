import React, { useState } from 'react'
import styled from 'styled-components'
import { Input, Button, Icon, Select } from '../omg-uikit'
import Modal from '../omg-modal'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import { createApiKey } from '../omg-api-keys/action'
import PropTypes from 'prop-types'
const CreateAdminKeyModalContainer = styled.div`
  padding: 50px;
  width: 100vw;
  height: 100vh;
  position: relative;
  box-sizing: border-box;
  text-align: center;
  > i {
    position: absolute;
    right: 30px;
    top: 30px;
    font-size: 30px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  h4 {
    margin-bottom: 35px;
    text-align: center;
  }
  > button {
    margin-top: 35px;
  }
`
const CreateAdminKeyButton = styled(Button)`
  padding-left: 40px;
  padding-right: 40px;
`
const CreateAdminKeyFormContainer = styled.form`
  position: absolute;
  top: 50%;

  transform: translateY(-50%);
  left: 0;
  right: 0;
  margin: 0 auto;
  width: 400px;
`
const StyledInput = styled(Input)`
  margin-bottom: 30px;
`
const enhance = compose(
  withRouter,
  connect(
    null,
    { createApiKey }
  )
)

CreateAdminKeyModal.propTypes = {
  open: PropTypes.bool,
  createApiKey: PropTypes.func,
  onRequestClose: PropTypes.func,
  onSubmitSuccess: PropTypes.func
}

function CreateAdminKeyModal (props) {
  const [name, setName] = useState()
  const [submitStatus, setSubmitStatus] = useState()
  function onRequestClose () {
    props.onRequestClose()
    setName()
    setSubmitStatus()
  }
  async function onSubmit (e) {
    e.preventDefault()
    setSubmitStatus('SUBMITTED')
    const { data } = await props.createApiKey({ name })
    if (data) {
      setSubmitStatus('SUCCESS')
      props.onSubmitSuccess(data)
      onRequestClose()
    }
  }

  return (
    <Modal
      isOpen={props.open}
      onRequestClose={onRequestClose}
      contentLabel='invite modal'
      shouldCloseOnOverlayClick={false}
      overlayClassName='dummy'
    >
      <CreateAdminKeyModalContainer onSubmit={onSubmit}>
        <Icon name='Close' onClick={onRequestClose} />
        <CreateAdminKeyFormContainer>
          <h4>Create Client Key</h4>
          <StyledInput
            autoFocus
            placeholder='Label'
            onChange={e => setName(e.target.value)}
            value={name}
          />
          <CreateAdminKeyButton
            styleType='primary'
            type='submit'
            loading={submitStatus === 'SUBMITTED'}
          >
            Create key
          </CreateAdminKeyButton>
        </CreateAdminKeyFormContainer>
      </CreateAdminKeyModalContainer>
    </Modal>
  )
}

export default enhance(CreateAdminKeyModal)
