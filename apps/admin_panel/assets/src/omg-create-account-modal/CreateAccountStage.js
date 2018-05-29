import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input, Button, Icon, AddButton } from '../omg-uikit'
import ImageUploaderAvatar from '../omg-uploader/ImageUploaderAvatar'
const CreateAddTitle = styled.div`
  margin-top: 35px;
  text-align: left;
  font-size: 14px;
  > span {
    color: ${props => props.theme.colors.S500};
  }
`
const CategoryActionContainer = styled.div`
  display: flex;
  align-items: flex-end;
  > input {
    flex: 1 1 auto;
    margin-top: 0;
  }
  > button {
    flex: 0 0 auto;
    margin: 15px 5px 0 0;
    margin-right: 5px;
  }
`
const Form = styled.form`
  padding: 50px;
  > i {
    position: absolute;
    right: 15px;
    top: 15px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  input {
    margin-top: 50px;
  }
  button {
    margin: 35px 0 0;
    font-size: 14px;
  }
`

export default class CreateAccountStage extends Component {
  static propTypes = {
    submitting: PropTypes.bool,
    onRequestClose: PropTypes.func,
    onClickAddCategory: PropTypes.func,
    onSubmit: PropTypes.func,
    onClickCreateAccount: PropTypes.func,
    name: PropTypes.string,
    description: PropTypes.string,
    onChangeInputName: PropTypes.func,
    onChangeInputDescription: PropTypes.func,
    onChangeAvatar: PropTypes.func,
    error: PropTypes.string,
    avatar: PropTypes.string
  }

  render () {
    return (
      <Form onSubmit={this.props.onSubmit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4>Create Account</h4>
        <ImageUploaderAvatar onChangeImage={this.props.onChangeAvatar} placeholder={this.props.avatar} />
        <Input
          placeholder='name'
          autofocus
          value={this.props.name}
          onChange={this.props.onChangeInputName}
        />
        <Input
          placeholder='description'
          value={this.props.description}
          onChange={this.props.onChangeInputDescription}
        />
        <CreateAddTitle>
          Create / Add to category <span>(Optional)</span>
        </CreateAddTitle>
        <CategoryActionContainer>
          <AddButton onClick={this.props.onClickAddCategory} type='button' />
        </CategoryActionContainer>
        <Button
          size='small'
          type='submit'
          loading={this.props.submitting}
          onClick={this.props.onClickCreateAccount}
        >
          Create account
        </Button>
        <div>{this.props.error}</div>
      </Form>
    )
  }
}
