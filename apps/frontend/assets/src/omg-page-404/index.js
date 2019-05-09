import React, { useEffect, useState } from 'react'
import PropTypes from 'prop-types'
import { withRouter } from 'react-router-dom'
import styled from 'styled-components'

import { Button } from '../omg-uikit'

const Container = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 100vh;

  h4 {
    padding-bottom: 10px;
  }

  p {
    padding-bottom: 20px;
  }
`

const ImgContainer = styled.div`
  opacity: ${props => props.loaded ? 1 : 0};
  transition: opacity 300ms ease-in;

  img {
    height: 150px;
    margin-bottom: 50px;
  }
`

const NotFoundPage = (props) => {
  const [loaded, setLoaded] = useState(false)

  useEffect(() => {
    setLoaded(true)
  }, [])

  function handleClick () {
    props.history.push('/')
  }

  return (
    <Container>
      <ImgContainer loaded={loaded}>
        <img src={require('../../statics/images/empty_state.png')} />
      </ImgContainer>

      <h4>{'Page Not Found'}</h4>
      <p>{'Sorry, the page you are looking for does not exist.'}</p>

      <Button
        styleType='primary'
        size='medium'
        onClick={handleClick}
      >
        <span>Go Back Home</span>
      </Button>
    </Container>
  )
}

NotFoundPage.propTypes = {
  history: PropTypes.object
}

export default withRouter(NotFoundPage)
