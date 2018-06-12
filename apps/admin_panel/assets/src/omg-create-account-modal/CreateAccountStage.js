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
  text-align: left;
  margin-top: 35px;
  > button {
    margin-right: 5px;
    vertical-align: middle;
    display: inline-block;
  }
  span {
    vertical-align: middle;
    display: inline-block;
    margin-left: 10px;
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
  > button {
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
    avatar: PropTypes.string,
    category: PropTypes.object
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
          error={this.props.error}
          errorText={this.props.error}
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
          <span>{_.get(this.props.category, 'name')}</span>
        </CategoryActionContainer>
        <Button
          size='small'
          type='submit'
          loading={this.props.submitting}
          onClick={this.props.onClickCreateAccount}
        >
          Create account
        </Button>
      </Form>
    )
  }
}
