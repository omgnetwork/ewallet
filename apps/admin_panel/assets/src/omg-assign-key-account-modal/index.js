import React, { useState } from 'react'
import styled from 'styled-components'
import { Button, Icon, Select } from '../omg-uikit'
import Modal from '../omg-modal'
import { connect } from 'react-redux'
import AccessKeysFetcher from '../omg-access-key/accessKeysFetcher'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import { createAccessKey } from '../omg-access-key/action'
import { assignKey } from '../omg-account/action'
import PropTypes from 'prop-types'
import AdminKeySelectRow from './AdminKeySelectRow'
const AssignKeyAccountContainer = styled.div`
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

AssignKeyAccount.propTypes = {
  open: PropTypes.bool,
  onRequestClose: PropTypes.func,
  onSubmitSuccess: PropTypes.func,
  assignKey: PropTypes.func,
  accountId: PropTypes.string
}
AssignKeyAccount.defaultProps = {
  onSubmitSuccess: _.noop
}

function AssignKeyAccount (props) {
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')
  const [roleAccount, setRoleAccount] = useState('viewer')
  const [adminKey, setAdminKeyInput] = useState('')
  function onRequestClose () {
    setAdminKeyInput('')
    setSubmitStatus('DEFAULT')
    props.onRequestClose()
  }
  function onSelectAccount (account) {
    setAdminKeyInput(account)
  }
  async function onSubmit (e) {
    e.preventDefault()
    setSubmitStatus('SUBMITTED')
    const { data } = await props.assignKey({
      keyId: adminKey,
      accountId: props.accountId,
      role: roleAccount
    })
    if (data) {
      setSubmitStatus('SUCCESS')
      console.log(props)
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
      <AssignKeyAccountContainer onSubmit={onSubmit}>
        <Icon name='Close' onClick={onRequestClose} />
        <CreateAdminKeyFormContainer>
          <h4>Assign Admin Key</h4>
          <InputLabel>Key To Assign</InputLabel>
          <AccessKeysFetcher
            query={{
              perPage: 10,
              search: adminKey
            }}
            render={({ data: adminKeys }) => {
              return (
                <StyledSelect
                  normalPlaceholder='Account ( optional )'
                  onChange={e => setAdminKeyInput(e.target.value)}
                  value={adminKey}
                  onSelectItem={item => onSelectAccount(item.key)}
                  options={adminKeys.map(k => (
                    {key: k.id, value: <AdminKeySelectRow key={k.id} adminKey={k} />}
                  ))}
                />
              )
            }}
          />
          <InputLabel>Account Role</InputLabel>
          <StyledSelect
            normalPlaceholder={'Account\'s Role'}
            value={_.upperFirst(roleAccount)}
            onSelectItem={item => setRoleAccount(item.key)}
            options={[
              { key: 'viewer', value: 'Viewer' },
              { key: 'admin', value: 'Admin' }
            ]}
          />
          <CreateAdminKeyButton
            styleType='primary'
            type='submit'
            loading={submitStatus === 'SUBMITTED'}
          >
            Assign Key
          </CreateAdminKeyButton>
        </CreateAdminKeyFormContainer>
      </AssignKeyAccountContainer>
    </Modal>
  )
}

export default enhance(AssignKeyAccount)
