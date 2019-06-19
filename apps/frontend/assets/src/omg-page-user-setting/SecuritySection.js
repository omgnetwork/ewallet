import React, { useCallback } from 'react'
import styled from 'styled-components'
import { useDispatch, useSelector } from 'react-redux'
import { selectCurrentUser } from '../omg-user-current/selector'
import { Button } from '../omg-uikit'
import { openModal } from '../omg-modal/action'

const SecurityContainer = styled.div`
  h3 {
    margin: 20px 0;
  }
  .enable-two-fa {
    margin-left: 20px;
  }
`
function SecuritySeciton () {
  const currentUser = useSelector(selectCurrentUser)
  const dispatch = useDispatch()
  const onClickEnable2Fa = useCallback(
    () => openModal({ id: 'enable2FaModal' })(dispatch),
    []
  )
  const onClickDisable2Fa = useCallback(
    () => openModal({ id: 'disable2FaModal' })(dispatch),
    []
  )

  return (
    <SecurityContainer>
      <h3>Security</h3>
      <div
        style={{
          border: '1px solid lightgrey',
          padding: '10px',
          display: 'inline-block',
          borderRadius: '4px'
        }}
      >
        Two Factor Authentication
        <Button
          className='enable-two-fa'
          onClick={
            currentUser.enabled_2fa_at ? onClickDisable2Fa : onClickEnable2Fa
          }
        >
          {currentUser.enabled_2fa_at ? 'Disable' : 'Enable'}
        </Button>
      </div>
    </SecurityContainer>
  )
}

export default SecuritySeciton
