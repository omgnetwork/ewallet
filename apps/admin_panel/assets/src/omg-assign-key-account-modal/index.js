import React, { useState } from 'react'
import styled from 'styled-components'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'

import { Button, Icon, Select } from '../omg-uikit'
import Modal from '../omg-modal'
import AccessKeysFetcher from '../omg-access-key/accessKeysFetcher'
import { assignKey } from '../omg-account/action'
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
  h3 {
    margin-bottom: 35px;
    text-align: left;
  }
  button {
    display: block;
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
const StyledSelect = styled(Select)`
  margin-bottom: 35px;
  text-align: left;
`
const InputLabel = styled.div`
  text-align: left;
  margin-bottom: 5px;
`

function AssignKeyAccount (props) {
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')
  const [role, setRole] = useState('viewer')

  const [keyId, setKeyId] = useState(props.keyId || '')

  function onRequestClose () {
    setKeyId('')
    props.onRequestClose()
  }

  function onSelectKey (item) {
    setKeyId(item.key)
  }

  async function onSubmit (e) {
    e.preventDefault()
    setSubmitStatus('SUBMITTED')
    const { data } = await props.assignKey({ keyId, accountId: props.accountId, role })
    if (data) {
      setSubmitStatus('SUCCESS')
      props.onSubmitSuccess()
      onRequestClose()
    } else {
      setSubmitStatus('FAILED')
    }
  }

  function renderAssignKey () {
    return (
      <AssignKeyAccountContainer onSubmit={onSubmit}>
        <Icon name='Close' onClick={onRequestClose} />
        <CreateAdminKeyFormContainer>
          <h3>Assign Admin Key</h3>

          <InputLabel>Assign Key</InputLabel>
          <AccessKeysFetcher
            query={{
              perPage: 10,
              search: keyId
            }}
            render={({ data: adminKeys }) => {
              return (
                <StyledSelect
                  disabled={!!props.keyId}
                  normalPlaceholder='Admin Key'
                  onChange={e => setKeyId(e.target.value)}
                  value={keyId}
                  onSelectItem={onSelectKey}
                  options={adminKeys.map(k => ({
                    key: k.id,
                    value: <AdminKeySelectRow key={k.id} adminKey={k} />
                  }))}
                />
              )
            }}
          />

          <InputLabel>Account Role</InputLabel>
          <StyledSelect
            normalPlaceholder={'Account\'s Role'}
            value={_.startCase(role)}
            onSelectItem={item => setRole(item.key)}
            options={[
              { key: 'admin', value: 'Admin' },
              { key: 'viewer', value: 'Viewer' }
            ]}
          />

          <Button
            styleType='primary'
            type='submit'
            loading={submitStatus === 'SUBMITTED'}
          >
            <span>Assign Key</span>
          </Button>

        </CreateAdminKeyFormContainer>
      </AssignKeyAccountContainer>
    )
  }

  return (
    <Modal
      isOpen={props.open}
      onRequestClose={onRequestClose}
      contentLabel='assign-key-modal'
      overlayClassName='dummy'
      shouldCloseOnOverlayClick
    >
      {renderAssignKey()}
    </Modal>
  )
}

const enhance = compose(
  withRouter,
  connect(
    null,
    { assignKey }
  )
)

AssignKeyAccount.propTypes = {
  open: PropTypes.bool,
  onRequestClose: PropTypes.func,
  onSubmitSuccess: PropTypes.func,
  assignKey: PropTypes.func,
  keyId: PropTypes.string,
  accountId: PropTypes.string.isRequired
}
AssignKeyAccount.defaultProps = {
  onSubmitSuccess: _.noop
}

export default enhance(AssignKeyAccount)
