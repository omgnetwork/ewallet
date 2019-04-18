import React from 'react';
import styled from 'styled-components';

import { Button } from '../omg-uikit';

const DeleteExchangeModalStyle = styled.div`
  padding: 50px;
  white-space: pre;
  display: flex;
  flex-direction: column;
  justify-content: center;
  text-align: center;
`;

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
`;

const DeleteExchangeModal = ({ toDelete, onRequestClose }) => {
  if (!toDelete) return null;

  const {
    from_token: { symbol: fromSymbol },
    to_token: { symbol: toSymbol },
    rate
  } = toDelete;

  const deletePair = () => {
    console.log('deleting...');
    onRequestClose();
  }

  return (
    <DeleteExchangeModalStyle>
      {`Are you sure you want to delete\nthe exchange pair 1 ${fromSymbol} = ${_.round(rate, 3)} ${toSymbol}?`}
      <ButtonGroup>
        <Button onClick={deletePair}>
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
  );
}

export default DeleteExchangeModal;
