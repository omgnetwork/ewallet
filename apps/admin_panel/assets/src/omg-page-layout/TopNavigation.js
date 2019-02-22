import React, { PureComponent } from 'react'
import styled from 'styled-components'

import PropTypes from 'prop-types'
import SearchGroup from './SearchGroup'
const TopNavigationContainer = styled.div`
  padding: 20px 0;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  width: 100%;
  h2 {
    display: inline-block;
    margin-right: 25px;
    font-size: 24px;
  }
  > {
    vertical-align: middle;
  }
`
const LeftNavigationContainer = styled.div`
  flex: 1 1 auto;
`
const RightNavigationContainer = styled.div`
  white-space: nowrap;
  button {
    font-size: 14px;
    i {
      margin-right: 10px;
    }
    span {
      vertical-align: middle;
    }
  }
  button:not(:first-child) {
    margin-left: 10px;
  }
  @media screen and (max-width: 769px) {
    flex: 1 0 100%;
    margin-top: 10px;
  }
`
const SecondaryActionsContainer = styled.div`
  vertical-align: bottom;
  display: inline-block;
`

export default class TopNavigation extends PureComponent {
  static propTypes = {
    buttons: PropTypes.array,
    title: PropTypes.string,
    secondaryAction: PropTypes.bool,
    normalPlaceholder: PropTypes.string
  }
  static defaultProps = {
    secondaryAction: true
  }
  renderSecondaryActions () {
    return (
      <SecondaryActionsContainer>
        <SearchGroup normalPlaceholder={this.props.normalPlaceholder} />
      </SecondaryActionsContainer>
    )
  }
  render () {
    return (
      <TopNavigationContainer>
        <LeftNavigationContainer>
          <h2>{this.props.title}</h2>
        </LeftNavigationContainer>
        <RightNavigationContainer>
          {this.props.secondaryAction && this.renderSecondaryActions()}
          {this.props.buttons}
        </RightNavigationContainer>
      </TopNavigationContainer>
    )
  }
}
