import React, { useState } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import styled from 'styled-components'

import { Button } from '../omg-uikit'
import { deleteExchangePair } from '../omg-exchange-pair/action'

const DeleteExchangeModalStyle = styled.div`
  padding: 50px;
  white-space: pre;
  display: flex;
  flex-direction: column;
  justify-content: center;
  text-align: center;
`

const ButtonGroup = styled.div`
  display: flex;
  flex-direction: row;
  margin-top: 40px;

  button {
    flex: 1 1 0;

    &:last-child {
      margin-left: 10px;
    }
  }
`

const DeleteExchangeModal = ({ toDelete, onRequestClose, deleteExchangePair }) => {
  if (!toDelete) return null

  const [ submitting, setSubmitting ] = useState(false)

  const {
    from_token: { symbol: fromSymbol },
    to_token: { symbol: toSymbol },
    rate,
    id
  } = toDelete

  const deletePair = async () => {
    setSubmitting(true)
    await deleteExchangePair({ id })
    setSubmitting(false)
    onRequestClose()
  }

  return (
    <DeleteExchangeModalStyle>
      {`Are you sure you want to delete\nthe exchange pair 1 ${fromSymbol} = ${_.round(rate, 3)} ${toSymbol}?`}
      <ButtonGroup>
        <Button
          onClick={deletePair}
          loading={submitting}
        >
          Delete
        </Button>
        <Button
          onClick={onRequestClose}
          styleType='secondary'
        >
          Cancel
        </Button>
      </ButtonGroup>
    </DeleteExchangeModalStyle>
  )
}

DeleteExchangeModal.propTypes = {
  toDelete: PropTypes.object,
  onRequestClose: PropTypes.func,
  deleteExchangePair: PropTypes.func
}

const enhance = connect(
  null,
  { deleteExchangePair }
)

export default enhance(DeleteExchangeModal)
