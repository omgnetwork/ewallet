import React from 'react'
import styled from 'styled-components'
import { useDispatch } from 'react-redux'

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
  const dispatch = useDispatch()
  const onClickEnable2Fa = () => openModal({ id: 'create2faModal' })(dispatch)
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
        <Button className='enable-two-fa' onClick={onClickEnable2Fa}>
          Enable
        </Button>
      </div>
    </SecurityContainer>
  )
}

export default SecuritySeciton
