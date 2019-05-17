import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Avatar } from '../omg-uikit'

const StyledAvatar = styled(Avatar)`
  display: inline-block;
  vertical-align: middle;
  margin-right: 10px;
`
const AccountSelectContainer = styled.div`
  position: relative;
  white-space: nowrap;
`
const DetailContainer = styled.div`
  display: inline-block;
  vertical-align: middle;
`
const Name = styled.div``
const Identifier = styled.div`
  color: ${props => props.theme.colors.SL100};
  font-size: 10px;
`
const AccountSelect = ({ account }) => {
  const name = _.get(account, 'name')
  const identifier = _.get(account, 'id')
  const thumbnail = _.get(account, 'avatar.thumb')

  return (
    <AccountSelectContainer>
      <StyledAvatar image={thumbnail} name={name} />
      <DetailContainer>
        <Name>{name}</Name>
        <Identifier>
          {identifier}
        </Identifier>
      </DetailContainer>
    </AccountSelectContainer>
  )
}

AccountSelect.propTypes = {
  account: PropTypes.object
}

export default AccountSelect
