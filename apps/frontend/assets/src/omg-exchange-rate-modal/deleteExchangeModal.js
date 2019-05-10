import React, { useState } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import styled from 'styled-components'

import { Button, Checkbox } from '../omg-uikit'
import { deleteExchangePair } from '../omg-exchange-pair/action'

const DeleteExchangeModalStyle = styled.div`
  padding: 50px;
  white-space: pre;
  display: flex;
  flex-direction: column;
  justify-content: center;
  text-align: center;

  p {
    padding-bottom: 20px;
  }
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
  const [ deleteOpp, setDeleteOpp ] = useState(false)

  const toggleDeleteOpp = () => {
    setDeleteOpp(prevBool => !prevBool)
  }

  const {
    from_token: { symbol: fromSymbol },
    to_token: { symbol: toSymbol },
    rate,
    id,
    opposite_exchange_pair_id: oppId,
    opposite_exchange_pair: opp
  } = toDelete

  const deletePair = async () => {
    setSubmitting(true)
    await deleteExchangePair({ id })
    if (deleteOpp) {
      await deleteExchangePair({ id: oppId })
    }
    setSubmitting(false)
    onRequestClose()
  }

  const currentPair = `1 ${fromSymbol} = ${_.round(rate, 3)} ${toSymbol}`
  const oppositePair = oppId ? `1 ${opp.from_token.symbol} = ${_.round(opp.rate, 3)} ${opp.to_token.symbol}` : ''

  return (
    <DeleteExchangeModalStyle>
      <p>{`Are you sure you want to delete\nthe exchange pair ${currentPair}?`}</p>

      {!!oppId && (
        <>
          <p>{`An opposite exchange pair of\n${oppositePair} exists.\nWould you also like to delete this pair?`}</p>
          <Checkbox
            label={`Delete ${oppositePair}`}
            checked={deleteOpp}
            onClick={toggleDeleteOpp}
          />
        </>
      )}

      <ButtonGroup>
        <Button
          onClick={deletePair}
          loading={submitting}
        >
          <span>Delete</span>
        </Button>
        <Button
          onClick={onRequestClose}
          styleType='secondary'
        >
          <span>Cancel</span>
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
