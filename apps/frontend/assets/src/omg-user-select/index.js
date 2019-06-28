import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Avatar } from '../omg-uikit'

const StyledAvatar = styled(Avatar)`
  display: inline-block;
  vertical-align: middle;
  margin-right: 10px;
`
const UserSelectContainer = styled.div`
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
const UserSelect = ({ user }) => {
  const username = _.get(user, 'username') || ''
  const provideruserid = _.get(user, 'provider_user_id') || ''
  const email = _.get(user, 'email') || ''
  const identifier = _.get(user, 'id') || ''
  const thumbnail = _.get(user, 'avatar.thumb')

  return (
    <UserSelectContainer>
      <StyledAvatar image={thumbnail} name={username || provideruserid || email} />
      <DetailContainer>
        <Name>{username || provideruserid || email }</Name>
        <Identifier>
          {identifier}
          {`${(username || provideruserid) && email ? ` - ${email}` : ''}`}
        </Identifier>
      </DetailContainer>
    </UserSelectContainer>
  )
}

UserSelect.propTypes = {
  user: PropTypes.object
}

export default UserSelect
