import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

const TabHeadersContainer = styled.div`
  display: flex;
`
const TabPanelContainer = styled.div`
  position: relative;
`
const TabHeader = styled.div`
  flex: 1 1 auto;
  cursor: pointer;
  font-size: 10px;
  text-align: left;
  font-weight: 600;
  padding: 10px 0;
  text-align: center;
  border-radius: 2px;
  color: ${props => (props.active ? props.theme.colors.B400 : props.theme.colors.S500)};
  background-color: ${props => (props.active ? props.theme.colors.S300 : 'white')};
`
const TabContent = styled.div`
  position: relative;
`
export default class TabPanel extends Component {
  static propTypes = {
    activeTabKey: PropTypes.string,
    data: PropTypes.array,
    onClickTab: PropTypes.func
  }
  render () {
    return (
      <TabPanelContainer>
        <TabHeadersContainer>
          {this.props.data.map(d => {
            return (
              <TabHeader
                key={d.key}
                active={this.props.activeTabKey === d.key}
                onClick={this.props.onClickTab(d.key)}
              >
                {d.tabTitle}
              </TabHeader>
            )
          })}
        </TabHeadersContainer>
        <TabContent>
          {_.get(
            _.filter(this.props.data, d => d.key === this.props.activeTabKey)[0],
            'tabContent'
          )}
        </TabContent>
      </TabPanelContainer>
    )
  }
}
