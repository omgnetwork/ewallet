import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

const TabManagerContainer = styled.div``

const TabContainer = styled.div``

const TabTitle = styled.div`
  border-bottom: 3px solid ${props => props.active ? props.theme.colors.BL400} : 'transparent'};
`
const TabTitleContainer = styled.div`
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
          {this.props.tabs.map((tab,i) => (
            <TabTitle active={this.props.activeIndex === i}>{tab.title}</TabTitle>
          ))}
        </TabTitleContainer>
        <TabContent>
          {this.props.tabs[this.props.activeIndex].content}
        </TabContent>
      </TabManagerContainer>
    )
  }
}
