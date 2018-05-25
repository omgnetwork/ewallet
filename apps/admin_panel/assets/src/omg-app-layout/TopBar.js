import React, { PureComponent } from 'react'
import styled from 'styled-components'
import ProfileAvatarDropdown from './ProfileDropdown'
const TopBarContainer = styled.div`
  padding: 8px 5%;
  text-align: right;
`
export default class TopBar extends PureComponent {

  render () {
    return (
      <TopBarContainer>
        {/* <GlobalSearchBar /> */}
        <ProfileAvatarDropdown />
      </TopBarContainer>
    )
  }
}
