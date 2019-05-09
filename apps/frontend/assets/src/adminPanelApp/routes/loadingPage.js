import React, { Component } from 'react'
import styled from 'styled-components'
const Container = styled.div`
  position: relative;
  height: 100vh;
  overflow: hidden;
  img {
    max-width: 200px;
  }
`
const Center = styled.div`
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  left: 0;
  right: 0;
  text-align: center;
  margin: 0 auto;
`
export default class BootupPage extends Component {
  render () {
    return (
      <Container>
        <Center>
          <img src={require('../../../statics/images/omisego_logo_black.png')} />
        </Center>
      </Container>
    )
  }
}
