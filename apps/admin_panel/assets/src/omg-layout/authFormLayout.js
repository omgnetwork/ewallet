import React, { Component } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'

const Container = styled.div`
  position: relative;
  height: 100vh;
  overflow: hidden;
  input {
    margin-top: 35px;
    font-size: 18px;
  }
  button {
    margin-top: 50px;
  }
  a {
    vertical-align: middle;
    :hover {
      color: ${props => props.theme.colors.BL400};
    }
    color: ${props => props.theme.colors.B100};
  }
`
export const FormContainer = styled.div`
  position: absolute;
  left: 0;
  right: 0;
  max-width: 440px;
  margin: 0 auto;
  top: 20%;
  text-align: center;
  padding: 20px;
`
const OmisegoLogo = styled.img.attrs({
  src: require('../../statics/images/omisego_logo_black.png')
})`
  width: 100%;
  max-width: 350px;
`
const Content = styled.div`
  position: relative;
`

const AuthFormLayout = class extends Component {
  static propTypes = {
    children: PropTypes.node
  }

  render () {
    return (
      <Container>
        <FormContainer>
          <OmisegoLogo />
          <Content>{this.props.children}</Content>
        </FormContainer>
      </Container>
    )
  }
}

export default AuthFormLayout
