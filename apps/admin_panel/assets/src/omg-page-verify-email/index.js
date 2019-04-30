import React, { useEffect, useState } from 'react'
import PropTypes from 'prop-types'
import { withRouter, Link } from 'react-router-dom'
import styled from 'styled-components'
import queryString from 'query-string'
import { connect } from 'react-redux'
import { compose } from 'recompose'

import { verifyEmail } from '../omg-session/action'
import { Button } from '../omg-uikit'

const StyledVerifyEmail = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 100%;

  h1 {
    padding-bottom: 10px;
  }

  .description {
    padding-bottom: 20px;
  }
`

const VerifyEmail = ({ location: { search }, verifyEmail }) => {
  const { email, token } = queryString.parse(search)
  const [ pageState, setPageState ] = useState('loading')

  useEffect(() => {
    doVerifyEmail()
  }, [])

  const doVerifyEmail = async () => {
    const res = await verifyEmail({ email, token })
    if (res.error) {
      setPageState('error')
    }
    if (res.data) {
      setPageState('success')
    }
  }

  const wording = {
    error: {
      title: 'Oops.',
      description: 'This link is invalid or has already been used.'
    },
    success: {
      title: 'Thank you.',
      description: `The email address ${email} is now verified.`
    }
  }

  return (
    <StyledVerifyEmail>
      {pageState === 'loading' ? (
        <div>Loading...</div>
      ) : (
        <>
          <h1>{wording[pageState].title}</h1>
          <p className='description'>
            {wording[pageState].description}
          </p>
          <Link to='/'>
            <Button size='large'>
              Go to Dashboard
            </Button>
          </Link>
        </>
      )}
    </StyledVerifyEmail>
  )
}

VerifyEmail.propTypes = {
  location: PropTypes.object,
  verifyEmail: PropTypes.func
}

const enhance = compose(
  connect(
    null,
    { verifyEmail }
  ),
  withRouter
)

export default enhance(VerifyEmail)
