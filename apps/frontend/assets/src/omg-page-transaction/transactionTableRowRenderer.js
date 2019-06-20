import moment from 'moment'
import styled from 'styled-components'
import React from 'react'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import { Icon } from '../omg-uikit'
import Copy from '../omg-copy'
const TransactionIdContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i[name='Transaction'] {
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
    margin-right: 10px;
  }
`
const FromToContainer = styled.div`
  > div:first-child {
    white-space: nowrap;
    margin-bottom: 10px;
    span {
      vertical-align: middle;
    }
  }
`
const StatusContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i {
    color: white;
    font-size: 10px;
  }
`
const Sign = styled.span`
  width: 10px;
  display: inline-block;
  vertical-align: middle;
`
export const MarkContainer = styled.div`
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background-color: ${props =>
    props.status === 'failed' ? '#FC7166' : '#0EBF9A'};
  display: inline-block;
  text-align: center;
  line-height: 18px;
  margin-right: 5px;
`
const BoldSpan = styled.span`
  font-weight: bold;
`
const FromOrToRow = styled.div`
  white-space: nowrap;
`

const renderFromOrTo = fromOrTo => {
  return (
    <FromOrToRow>
      {fromOrTo.account && <BoldSpan>{fromOrTo.account.name}</BoldSpan>}
      {fromOrTo.user && fromOrTo.user.email && (
        <BoldSpan>{fromOrTo.user.email}</BoldSpan>
      )}
      {fromOrTo.user && fromOrTo.user.provider_user_id && (
        <BoldSpan>{fromOrTo.user.provider_user_id}</BoldSpan>
      )}
      <span> - {fromOrTo.address}</span>
    </FromOrToRow>
  )
}

export default (key, data, rows) => {
  if (key === 'id') {
    return (
      <TransactionIdContainer>
        <Icon name='Transaction' />
        <span>{data}</span> <Copy data={data} />
      </TransactionIdContainer>
    )
  }

  if (key === 'status') {
    return (
      <StatusContainer>
        {data === 'failed' ? (
          <MarkContainer status='failed'>
            <Icon name='Close' />
          </MarkContainer>
        ) : (
          <MarkContainer status='success'>
            <Icon name='Checked' />
          </MarkContainer>
        )}{' '}
        <span>{_.capitalize(data)}</span>
      </StatusContainer>
    )
  }
  if (key === 'toFrom') {
    return (
      <FromToContainer>
        <div>{renderFromOrTo(rows.from)}</div>
        <div>{renderFromOrTo(rows.to)}</div>
      </FromToContainer>
    )
  }
  if (key === 'fromToToken') {
    return (
      <FromToContainer>
        <div>
          <Sign>-</Sign>
          <span>
            {formatReceiveAmountToTotal(
              rows.from.amount,
              rows.from.token.subunit_to_unit
            )}{' '}
            {rows.from.token.symbol}
          </span>
        </div>
        <div>
          <Sign>+</Sign>
          <span>
            {formatReceiveAmountToTotal(
              rows.to.amount,
              rows.to.token.subunit_to_unit
            )}{' '}
            {rows.to.token.symbol}
          </span>
        </div>
      </FromToContainer>
    )
  }
  if (key === 'created_at') {
    return moment(data).format()
  }
  return data
}
