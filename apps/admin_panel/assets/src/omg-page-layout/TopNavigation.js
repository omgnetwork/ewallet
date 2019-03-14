import React, { PureComponent } from 'react'
import styled from 'styled-components'

import PropTypes from 'prop-types'
import SearchGroup from './SearchGroup'

const TopNavigationContainer = styled.div`
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  width: 100%;
  height: 80px;
  position: relative;
  margin-bottom: ${props => props.divider ? '20px' : '0'};
  h2 {
    display: inline-block;
    margin-right: 25px;
    font-size: 24px;
  }
  > {
    vertical-align: middle;
  }
  /* psuedu border bottom hack overide parent padding */
  :after {
    content: '';
    position: absolute;
    display: ${props => (props.divider ? 'block' : 'none')};
    bottom: 0;
    height: 1px;
    width: 150%;
    background-color: ${props => props.theme.colors.S300};
    left: -8%;
    margin: 0 auto;
  }
  @media screen and (max-width: 800px) {
    height: auto;
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
    normalPlaceholder: PropTypes.string,
    description: PropTypes.string,
    divider: PropTypes.bool
  }
  static defaultProps = {
    secondaryAction: true,
    divider: true
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
      <TopNavigationContainer divider={this.props.divider}>
        <LeftNavigationContainer>
          <h2>{this.props.title}</h2>
          {this.props.description && <p>{this.props.description}</p>}
        </LeftNavigationContainer>
        <RightNavigationContainer>
          {this.props.secondaryAction && this.renderSecondaryActions()}
          {this.props.buttons}
        </RightNavigationContainer>
      </TopNavigationContainer>
    )
  }
}
