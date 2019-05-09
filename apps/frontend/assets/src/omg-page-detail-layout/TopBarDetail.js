import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

const TopBarAction = styled.div`
  flex: 0 1 auto;
  margin-left: auto;
  button {
    
    font-size: 14px;
    :not(:last-child) {
      margin-right: 15px;
    }
  }
  span {
    vertical-align: middle;
  }
`
const TopBarTitle = styled.div`
  flex: 1 1 auto;
`
const TopBar = styled.div`
  display: flex;
  align-items: center;
  height: 80px;
`
export default class TopBarDetail extends Component {
  static propTypes = {
    title: PropTypes.string,
    buttons: PropTypes.array
  }

  render () {
    return (
      <TopBar>
        <TopBarTitle>
          <h3>{this.props.title}</h3>
        </TopBarTitle>
        <TopBarAction>
          {this.props.buttons}
        </TopBarAction>
      </TopBar>
    )
  }
}
