import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import { SearchBar } from '../omg-uikit'

const TopNavigationContainer = styled.div`
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  width: 100%;
  min-height: 80px;
  position: relative;
  padding: 10px 0;
  margin-bottom: ${props => props.divider ? '20px' : '0'};
  h2 {
    display: inline-block;
    margin-right: 25px;
    font-size: 24px;
  }
  p {
    color: ${props => props.theme.colors.B100};
  }
  > {
    vertical-align: middle;
  }
  /* pseudo border bottom hack overide parent padding */
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
`
const LeftNavigationContainer = styled.div`
  flex: 1 1 auto;
  p {
    padding-top: 5px;
  }
`
const RightNavigationContainer = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
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
  @media screen and (max-width: 768px) {
    flex: 1 0 100%;
    margin-top: 10px;
  }
`

export default class TopNavigation extends PureComponent {
  static propTypes = {
    buttons: PropTypes.array,
    title: PropTypes.oneOfType([PropTypes.string, PropTypes.object]),
    searchBar: PropTypes.bool,
    normalPlaceholder: PropTypes.string,
    description: PropTypes.string,
    divider: PropTypes.bool
  }
  static defaultProps = {
    searchBar: true,
    divider: true
  }
  render () {
    return (
      <TopNavigationContainer divider={this.props.divider}>
        <LeftNavigationContainer>
          <h2>{this.props.title}</h2>
          {this.props.description && <p>{this.props.description}</p>}
        </LeftNavigationContainer>
        <RightNavigationContainer>
          {this.props.searchBar && <SearchBar placeholder={this.props.normalPlaceholder} />}
          {this.props.buttons}
        </RightNavigationContainer>
      </TopNavigationContainer>
    )
  }
}
