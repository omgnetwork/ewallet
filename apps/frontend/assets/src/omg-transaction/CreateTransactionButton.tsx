import React from 'react'
import { useSelector, useDispatch } from 'react-redux'

import { Button, Icon } from 'omg-uikit'
import { openModal } from 'omg-modal/action'
import { selectInternalEnabled } from 'omg-configuration/selector'

interface CreateTransactionButtonProps {
  fromAddress?:string
}

function CreateTransactionButton ({ fromAddress }: CreateTransactionButtonProps) {
  const internalEnabled: boolean = useSelector(selectInternalEnabled())
  const dispatch = useDispatch()
  const handleClick = () => {
    dispatch(openModal({ id: 'createTransaction', fromAddress: fromAddress }))
  }

  return internalEnabled? (
    <Button
      key='create'
      size='small'
      styleType='primary'
      onClick={handleClick}
    >
      <Icon name='Transaction' />
      <span>Internal Transfer</span>
    </Button>
  ) : null
}

export default CreateTransactionButton