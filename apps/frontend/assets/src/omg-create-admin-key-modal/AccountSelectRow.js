import React from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'

import { Avatar, Id } from '../omg-uikit'

const AccountSelectRowContainer = styled.div`
  display: flex;
  justify-content: row;
  align-items: center;
  max-width: 400px;
  .data {
    color: ${props => props.theme.colors.B100};
  }
  > div:first-child {
    margin-right: 10px;
    text-overflow: ellipsis;
    overflow: hidden;
  }
`

const AccountSelectRow = ({ account, style, withCopy = false }) => {
  if (!account) return null
  return (
    <AccountSelectRowContainer style={style}>
      <Avatar name={account.name} image={account.avatar.thumb} />
      <div>
        <p>{account.name}</p>
        <Id withCopy={withCopy} maxChar={200}>{account.id}</Id>
      </div>
    </AccountSelectRowContainer>
  )
}

AccountSelectRow.propTypes = {
  account: PropTypes.object,
  style: PropTypes.object,
  withCopy: PropTypes.bool
}

export default AccountSelectRow
