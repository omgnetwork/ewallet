import React, { PureComponent } from 'react'
import styled from 'styled-components'
import { Link } from 'react-router-dom'

import PropTypes from 'prop-types'
import SearchGroup from './SearchGroup'
const TopNavigationContainer = styled.div`
  padding: 20px 0;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  h2 {
    display: inline-block;
    margin-right: 25px;
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
`
const TableType = styled.span`
  color: ${props => props.theme.colors.B100};
  font-size: 12px;
`
const Spliiter = styled.span`
  color: ${props => props.theme.colors.S400};
  margin: 0 ${props => (props.gap ? props.gap : '0')}px;
`
const SecondaryActionsContainer = styled.div`
  display: inline-block;
`

export default class TopNavigation extends PureComponent {
  static propTypes = {
    buttons: PropTypes.array,
    title: PropTypes.string,
    types: PropTypes.bool,
    secondaryAction: PropTypes.bool
  }
  static defaultProps = {
    types: true,
    secondaryAction: true
  }
  constructor (props) {
    super(props)
    this.types = ['History', 'Table Info']
  }
  renderTableTypes () {
    return (
      <SecondaryActionsContainer>
        {this.types.reduce((prev, curr, index) => {
          prev.push(
            <Link to='/' key={curr}>
              <TableType>{curr}</TableType>
            </Link>
          )
          if (index !== this.types.length - 1) {
            prev.push(
              <Spliiter key={`${curr}${index}`} gap={10}>
                |
              </Spliiter>
            )
          }
          return prev
        }, [])}
      </SecondaryActionsContainer>
    )
  }
  renderSecondaryActions () {
    return (
      <SecondaryActionsContainer>
        <SearchGroup />
        {/* <Spliiter>|</Spliiter>
        <Icon name='Filter' button /> */}
      </SecondaryActionsContainer>
    )
  }
  render () {
    return (
      <TopNavigationContainer>
        <LeftNavigationContainer>
          <h2>{this.props.title}</h2>
          {/* {this.props.types && this.renderTableTypes()} */}
        </LeftNavigationContainer>
        <RightNavigationContainer>
          {this.props.secondaryAction && this.renderSecondaryActions()}
          {this.props.buttons}
        </RightNavigationContainer>
      </TopNavigationContainer>
    )
  }
}
