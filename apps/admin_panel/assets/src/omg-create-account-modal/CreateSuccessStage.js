import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Button, PlainButton } from '../omg-uikit'
const ImageUpload = styled.div`
  height: 100px;
  width: 100px;
  background-color: ${props => props.theme.colors.S200};
  background-image: url(${props => props.placeholder});
  background-size: cover;
  background-position: center;
  border-radius: 4px;
  border: 1px solid ${props => props.theme.colors.S200};
  margin: 50px auto 0 auto;
  color: white;
  position: relative;
  transition: 0.2s;
`
const AccountDescription = styled.div`
  font-size: 14px;
  color: ${props => props.theme.colors.B100};
`
const CreateAccountSuccessContainer = styled.div`
  padding: 50px 50px;
  text-align: center;
  button {
    display: block;
    font-size: 14px;
    margin: 35px auto;
  }
  h5 {
    letter-spacing: 1px;
    margin-top: 50px;
    margin-bottom: 5px;
    font-size: 16px;
  }
`
export default class CreateAccountStage extends Component {
  static propTypes = {
    submitting: PropTypes.bool,
    onClickContinue: PropTypes.func,
    onClickFinish: PropTypes.func,
    name: PropTypes.string,
    description: PropTypes.string,
    avatar: PropTypes.string
  }

  render () {
    return (
      <CreateAccountSuccessContainer>
        <h4>Account successfully created</h4>
        <ImageUpload placeholder={this.props.avatar} />
        <h5>{this.props.name}</h5>
        <AccountDescription>{this.props.description}</AccountDescription>
        <AccountDescription>Category: Food</AccountDescription>
        <Button size='small' type='submit' loading={this.props.submitting} onClick={this.props.onClickContinue}>
          Continue Create Account
        </Button>
        <PlainButton onClick={this.props.onClickFinish}>Finished</PlainButton>
      </CreateAccountSuccessContainer>
    )
  }
}
