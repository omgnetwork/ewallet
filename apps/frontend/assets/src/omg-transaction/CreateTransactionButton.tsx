import React from 'react'
import { useSelector, useDispatch } from 'react-redux'

import { Button, Icon } from 'omg-uikit'
import { openModal } from 'omg-modal/action'
import { selectBlockchainEnabled } from 'omg-configuration/selector'

interface CreateTransactionButtonProps {
  fromAddress?:string
}

function CreateTransactionButton ({ fromAddress }: CreateTransactionButtonProps) {
  const blockchainEnabled: boolean = useSelector(selectBlockchainEnabled())
  const dispatch = useDispatch()
  const handleClick = () => {
    dispatch(openModal({ id: 'createTransaction', fromAddress: fromAddress }))
  }

  return blockchainEnabled? null: (
    <Button
      key='create'
      size='small'
      styleType='primary'
      onClick={handleClick}
    >
      <Icon name='Transaction' />
      <span>Internal Transfer</span>
    </Button>
  )
}

export default CreateTransactionButton