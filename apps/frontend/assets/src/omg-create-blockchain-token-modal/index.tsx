import React, { ChangeEventHandler, FormEventHandler, useState } from 'react'
import styled from 'styled-components'
import { useDispatch } from 'react-redux'

import { Input, Button, Icon, Checkbox } from 'omg-uikit'
import Modal from 'omg-modal'
import { createBlockchainToken } from 'omg-token/action'
import { formatAmount } from 'utils/formatter'

const Form = styled.form`
  padding: 50px;
  width: 250px;
  > i {
    position: absolute;
    right: 15px;
    top: 15px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  input {
    margin-top: 50px;
  }
  button {
    margin: 35px 0 0;
    font-size: 14px;
  }
  h4 {
    text-align: center;
  }
`
const ButtonContainer = styled.div`
  text-align: center;
`
const Error = styled.div<{ error: string }>`
  color: ${props => props.theme.colors.R400};
  text-align: center;
  padding: 10px 0;
  overflow: hidden;
  max-height: ${props => (props.error ? '100px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
`
const CheckboxContainer = styled.div`
  display: flex;
  flex-direction: row;
  margin-top: 20px;
`

interface createBlockchainTokenProps {
  refetch: Function
  onRequestClose: Function
}

const CreateBlockchainToken = ({
  refetch,
  onRequestClose
}: createBlockchainTokenProps) => {
  const dispatch = useDispatch()

  const [name, setName] = useState<string>('')
  const [symbol, setSymbol] = useState<string>('')
  const [unitAmount, setUnitAmount] = useState<string>('')
  const [decimal, setDecimal] = useState<number>(18)
  const [locked, setLocked] = useState<boolean>(true)

  const [submitting, setSubmitting] = useState<boolean>(false)
  const [error, setError] = useState<string>('')

  const onChangeInputName: ChangeEventHandler<HTMLInputElement> = e => {
    setName(e.target.value)
  }

  const onChangeInputSymbol: ChangeEventHandler<HTMLInputElement> = e => {
    setSymbol(e.target.value)
  }

  const onChangeAmount: ChangeEventHandler<HTMLInputElement> = e => {
    setUnitAmount(e.target.value)
  }

  const onChangeDecimal: ChangeEventHandler<HTMLInputElement> = e => {
    setDecimal(e.target.valueAsNumber)
  }

  const onToggleLocked = () => {
    setLocked(!locked)
  }

  const isValidDecimal = (): boolean => {
    return Number.isInteger(decimal) && decimal <= 18
  }
  const shouldSubmit = (): boolean => {
    return isValidDecimal() && !!name && !!symbol
  }

  const onSubmit: FormEventHandler<HTMLFormElement> = async e => {
    e.preventDefault()
    if (shouldSubmit() === false) return

    try {
      setSubmitting(true)

      const multiplier = Math.pow(10, decimal)
      const amount = formatAmount(
        unitAmount === '' ? '0' : unitAmount,
        multiplier
      )
      const creationOptions = { amount, decimal, locked, name, symbol }

      const result = await createBlockchainToken(creationOptions)(dispatch)
      if (result.data) {
        refetch()
        onRequestClose()
      } else {
        setSubmitting(false)
        setError(result.error.description || result.error.message)
      }
    } catch (e) {
      setSubmitting(false)
    }
  }
  return (
    <Form onSubmit={onSubmit} noValidate>
      <Icon name="Close" onClick={onRequestClose} />
      <h4>Create Blockchain Token</h4>
      <Input
        placeholder="Token Name"
        autofocus
        value={name}
        onChange={onChangeInputName}
      />
      <Input
        placeholder="Token Symbol"
        value={symbol}
        onChange={onChangeInputSymbol}
      />
      <Input
        placeholder="Decimal Points"
        value={decimal}
        onChange={onChangeDecimal}
        error={!isValidDecimal()}
        errorText={'Should be an integer less than or equal to 18.'}
        type="number"
        step={'1'}
      />
      <Input
        placeholder="Amount (Optional)"
        value={unitAmount}
        onChange={onChangeAmount}
        type="amount"
      />
      <CheckboxContainer>
        <Checkbox checked={locked} onClick={onToggleLocked} />
        <div>Lock this token to prevent further minting.</div>
      </CheckboxContainer>
      <ButtonContainer>
        <Button
          size="small"
          type="submit"
          loading={submitting}
          disabled={!shouldSubmit()}
        >
          <span>Create Token</span>
        </Button>
      </ButtonContainer>
      <Error error={error}>{error}</Error>
    </Form>
  )
}

interface CreateBlockchainTokenModalProps extends createBlockchainTokenProps {
  open: boolean
}

const CreateBlockchainTokenModal = ({
  open,
  onRequestClose,
  refetch
}: CreateBlockchainTokenModalProps) => {
  return (
    <Modal
      isOpen={open}
      onRequestClose={onRequestClose}
      contentLabel="create blockchain token modal"
    >
      <CreateBlockchainToken
        onRequestClose={onRequestClose}
        refetch={refetch}
      />
    </Modal>
  )
}

export default CreateBlockchainTokenModal
