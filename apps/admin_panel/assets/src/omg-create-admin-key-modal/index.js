import React, { useState } from 'react'
import styled from 'styled-components'
import Modal from '../omg-modal'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'

import { Input, Button, Icon, Select } from '../omg-uikit'
import { createAccessKey } from '../omg-access-key/action'
import { assignKey } from '../omg-account/action.js'

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
  margin-bottom: 35px;
`
const StyledSelect = styled(Select)`
  margin-bottom: 35px;
  text-align: left;
`
const InputLabel = styled.div`
  text-align: left;
  margin-bottom: 5px;
`
const enhance = compose(
  withRouter,
  connect(
    null,
    { createAccessKey, assignKey }
  )
)

CreateAdminKeyModal.propTypes = {
  open: PropTypes.bool,
  createAccessKey: PropTypes.func,
  onRequestClose: PropTypes.func,
  onSubmitSuccess: PropTypes.func,
  accountId: PropTypes.string
}

function CreateAdminKeyModal (props) {
  const [label, setLabel] = useState('')
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')
  const [role, setRole] = useState('none')
  const [roleName, setRoleName] = useState('viewer')

  function onRequestClose () {
    setLabel('')
    setRole('none')
    setSubmitStatus('DEFAULT')
    props.onRequestClose()
  }
  function onSelectRole (role) {
    setRole(role)
  }
  async function onSubmit (e) {
    e.preventDefault()
    setSubmitStatus('SUBMITTED')
    const { data } = await props.createAccessKey({
      name: label,
      globalRole: role,
      accountId: props.accountId,
      roleName
    })
    if (data) {
      setSubmitStatus('SUCCESS')
      props.onSubmitSuccess(data)
      onRequestClose()
    } else {
      setSubmitStatus('FAILED')
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
          <h4>Create Admin Key</h4>
          <InputLabel>Label</InputLabel>
          <StyledInput
            autoFocus
            normalPlaceholder='Label ( optional )'
            onChange={e => setLabel(e.target.value)}
            value={label}
          />
          {!props.accountId && (
            <>
              <InputLabel>Global Role</InputLabel>
              <StyledSelect
                normalPlaceholder='Role ( optional )'
                value={_.startCase(role)}
                onSelectItem={item => onSelectRole(item.key)}
                options={[
                  { key: 'super_admin', value: 'Super Admin' },
                  { key: 'admin', value: 'Admin' },
                  { key: 'viewer', value: 'Viewer' },
                  { key: 'none', value: 'None' }
                ]}
                optionRenderer={value => _.startCase(value)}
              />
            </>
          )}
          {props.accountId && (
            <>
              <InputLabel>Select Role</InputLabel>
              <StyledSelect
                normalPlaceholder='Role name'
                value={_.startCase(roleName)}
                onSelectItem={item => setRoleName(item.key)}
                options={[
                  { key: 'admin', value: 'Admin' },
                  { key: 'viewer', value: 'Viewer' }
                ]}
                optionRenderer={value => _.startCase(value)}
              />
            </>
          )}
          <Button
            styleType='primary'
            type='submit'
            loading={submitStatus === 'SUBMITTED'}
          >
            Create key
          </Button>
        </CreateAdminKeyFormContainer>
      </CreateAdminKeyModalContainer>
    </Modal>
  )
}

export default enhance(CreateAdminKeyModal)
