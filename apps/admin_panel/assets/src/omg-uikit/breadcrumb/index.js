import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
const BreadcrumbContainer = styled.div`
  position: relative;
  color: ${props => props.theme.colors.B100};
`
export default class Breadcrumb extends Component {
  static propTypes = {
    items: PropTypes.array.isRequired
  }

  render () {
    const items = this.props.items.filter(x => x)
    return (
      <BreadcrumbContainer>
        {items.reduce((prev, curr, index) => {
          prev.push(curr)
          if (index < items.length - 1) prev.push(' > ')
          return prev
        }, [])}
      </BreadcrumbContainer>
    )
  }
}
