import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

const TabManagerContainer = styled.div`
  margin-top: 10px;
`

const TabTitle = styled.div`
  border-bottom: 3px solid ${props => (props.active ? props.theme.colors.BL400 : 'transparent')};
  display: inline-block;
  font-weight: 600;
  font-size: 12px;
  cursor: pointer;
  :not(:last-child) {
    margin-right: 30px;
  }
  color: ${props => (props.active ? props.theme.colors.B400 : props.theme.colors.S500)};
`
const TabTitleContainer = styled.div`
  border-bottom: 1px solid ${props => props.theme.colors.S500};
`
const TabContent = styled.div`
`
export default class TabManager extends Component {
  static propTypes = {
    tabs: PropTypes.array.isRequired,
    activeIndex: PropTypes.number
  }

  static defaultProps = {
    activeIndex: 0
  }

  render () {
    return (
      <TabManagerContainer>
        <TabTitleContainer>
          {this.props.tabs.map((tab, i) => (
            <TabTitle active={this.props.activeIndex === i} key={i}>{tab.title}</TabTitle>
          ))}
        </TabTitleContainer>
        <TabContent>{this.props.tabs[this.props.activeIndex].content}</TabContent>
      </TabManagerContainer>
    )
  }
}
