import React from 'react'
import styled from 'styled-components'
import moment from 'moment'
import Copy from '../omg-copy'
import { Icon } from '../omg-uikit'

const WalletAddressContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i[name='Wallet'] {
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
    margin-right: 10px;
  }
  i[name='Copy'] {
    visibility: hidden;
    margin-left: 5px;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B300};
    }
  }
`
const StyledIcon = styled.span`
  i {
    margin-top: -3px;
    margin-right: 10px;
    margin-topfont-size: 14px;
    font-weight: 400;
  }
`

export default (key, data, rows) => {
  if (key === 'owner') {
    return (
      <span>
        {rows.account && (
          <span>
            <StyledIcon>
              <Icon name='Merchant' />
            </StyledIcon>
            {rows.account.name}
          </span>
        )}
        {rows.user && rows.user.email && (
          <span>
            <StyledIcon>
              <Icon name='People' />
            </StyledIcon>
            {rows.user.email}
          </span>
        )}
        {rows.user && rows.user.provider_user_id && (
          <span>
            <StyledIcon>
              <Icon name='People' />
            </StyledIcon>
            {rows.user.provider_user_id}
          </span>
        )}
        {rows.address === 'gnis000000000000' && (
          <span>
            <StyledIcon>
              <Icon name='Token' />
            </StyledIcon>
            Genesis
          </span>
        )}
      </span>
    )
  }
  if (key === 'name') {
    return (
      <WalletAddressContainer>
        <Icon name='Wallet' />
        <span>{data}</span>
      </WalletAddressContainer>
    )
  }
  if (key === 'created_at') {
    return moment(data).format()
  }
  if (key === 'identifier') {
    return (
      <WalletAddressContainer>
        <span>{data.split('_')[0]}</span>
      </WalletAddressContainer>
    )
  }
  if (key === 'address') {
    return (
      <WalletAddressContainer>
        <span>{data}</span> <Copy data={data} />
      </WalletAddressContainer>
    )
  }
  return data
}
