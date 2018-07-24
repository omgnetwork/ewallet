import React, { PureComponent } from 'react'
import styled from 'styled-components'
import ProfileAvatarDropdown from './ProfileDropdown'
const TopBarContainer = styled.div`
  padding: 15px 7% 10px 7%;
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
