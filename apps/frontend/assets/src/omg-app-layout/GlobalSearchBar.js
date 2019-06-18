import React, { PureComponent } from 'react'
import styled from 'styled-components'

import { Icon } from '../omg-uikit'

const GlobalSearchBarContainer = styled.div`
  position: relative;
  i {
    color: ${props => props.theme.colors.S400};
    font-size: 20px;
    vertical-align: middle;
  }
  input {
    margin-left: 10px;
    border: none;
    vertical-align:middle;
    width: calc(100% - 50px)
  }
`
class GlobalSearchBar extends PureComponent {
  render () {
    return (
      <GlobalSearchBarContainer {...this.props}>
        <Icon name='Search' /><input />
      </GlobalSearchBarContainer>
    )
  }
}
export default GlobalSearchBar
