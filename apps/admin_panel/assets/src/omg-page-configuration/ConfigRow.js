import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input } from '../omg-uikit'
const ConfigRowContainer = styled.div`
  display: flex;
`
const ConfigCol = styled.div`
  flex: 1 1 auto;
  padding: 20px;
  vertical-align: bottom;
`

export default class ConfigRow extends Component {
  static propTypes = {
    description: PropTypes.string,
    value: PropTypes.string,
    name: PropTypes.string
  }

  render () {
    return (
      <ConfigRowContainer>
        <ConfigCol>{this.props.name}</ConfigCol>
        <ConfigCol>{this.props.description}</ConfigCol>
        <ConfigCol>
          <Input value={this.props.value} />
        </ConfigCol>
      </ConfigRowContainer>
    )
  }
}
