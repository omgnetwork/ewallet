import React from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import { Avatar } from '../omg-uikit'
const AccountSelectRowContainr = styled.div`
  display: flex;
  align-items: center;
  > div:first-child {
    margin-right: 10px;
  }
`
const AccountSelectRowName = styled.div`
  margin-bottom: 5px;
`
const AccountSelectRowId = styled.div`
  color: ${props => props.theme.colors.B100};
  font-size: 12px;
`

AccountSelectRow.propTypes = {
  account: PropTypes.object
}
export default function AccountSelectRow ({ account }) {
  return (
    <AccountSelectRowContainr>
      <Avatar image={account.avatar.thumb} name={account.name} size={35} />
      <div>
        <AccountSelectRowName>{account.name}</AccountSelectRowName>
        <AccountSelectRowId>{account.id}</AccountSelectRowId>
      </div>
    </AccountSelectRowContainr>
  )
}
