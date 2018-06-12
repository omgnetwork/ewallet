import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Modal from 'react-modal'
import styled from 'styled-components'
import CreateAccountStage from './CreateAccountStage'
import ChooseCategoryStage from './ChooseCategoryStage'
import CreateSuccessStage from './CreateSuccessStage'
import { createAccount } from '../omg-account/action'
import { compose } from 'recompose'
import { connect } from 'react-redux'
const customStyles = {
  content: {
    top: '50%',
    left: '50%',
    right: 'auto',
    bottom: 'auto',
    marginRight: '-50%',
    transform: 'translate(-50%, -50%)',
    border: 'none',
    padding: 0,
    overflow: 'hidden'
  },
  overlay: {
    backgroundColor: 'rgba(0,0,0,0.5)'
  }
}
const CreateAccountContainer = styled.div`
  position: relative;
  text-align: center;
  width: 380px;
  height: 600px;
`
class CreateAccountModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    createAccount: PropTypes.func
  }
  state = {
    submitting: false,
    stage: 'create',
    name: '',
    description: '',
    avatar: '',
    category: '',
    error: null
  }

  onSubmit = e => {
    e.preventDefault()
    this.setState({ submitting: true })
  }
  onClickAddCategory = e => {
    this.setState({ stage: 'category' })
  }
  onClickBack = e => {
    this.setState({ stage: 'create' })
  }
  onClickCreateAccount = async e => {
    const result = await this.props.createAccount({
      name: this.state.name,
      description: this.state.description,
      avatar: this.state.avatar,
      category: this.state.category ? this.state.category.id : null
    })
    if (result.data.success) {
      this.setState({ stage: 'finished' })
    } else {
      this.setState({
        error: result.data.data.description,
        submitting: false
      })
    }
  }
  onClickContinue = e => {
    this.resetState()
  }
  resetState = () => {
    this.setState({
      stage: 'create',
      name: '',
      description: '',
      avatar: '',
      avatarPath: '',
      error: '',
      category: '',
      submitting: false
    })
  }
  onRequestClose = () => {
    this.resetState()
    this.props.onRequestClose()
  }
  onClickAddCategory = () => {
    this.setState({ stage: 'category' })
  }
  onChangeInputName = e => {
    this.setState({ name: e.target.value, error: false })
  }
  onChangeInputDescription = e => {
    this.setState({ description: e.target.value })
  }
  onChangeAvatar = ({ file, image, path }) => {
    this.setState({ avatar: file, avatarPath: path })
  }
  onChooseCategory = category => {
    this.setState({ category, stage: 'create' })
  }
  render () {
    const stageComponent = {
      create: (
        <CreateAccountStage
          submitting={this.state.submitting}
          onRequestClose={this.onRequestClose}
          onSubmit={this.onSubmit}
          onClickAddCategory={this.onClickAddCategory}
          onClickCreateAccount={this.onClickCreateAccount}
          name={this.state.name}
          onChangeInputName={this.onChangeInputName}
          description={this.state.description}
          onChangeInputDescription={this.onChangeInputDescription}
          error={this.state.error}
          onChangeAvatar={this.onChangeAvatar}
          avatar={this.state.avatarPath}
          category={this.state.category}
        />
      ),
      category: (
        <ChooseCategoryStage
          category={this.state.category}
          onClickBack={this.onClickBack}
          onChooseCategory={this.onChooseCategory}
          goToStage={this.goToStage}
        />
      ),
      finished: (
        <CreateSuccessStage
          onClickContinue={this.onClickContinue}
          onClickFinish={this.onRequestClose}
          name={this.state.name}
          category={this.state.category}
          description={this.state.description}
          avatar={this.state.avatarPath}
        />
      )
    }
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.onRequestClose}
        style={customStyles}
        contentLabel='create account modal'
        shouldCloseOnOverlayClick={false}
      >
        <CreateAccountContainer>{stageComponent[this.state.stage]}</CreateAccountContainer>
      </Modal>
    )
  }
}

const enhance = compose(
  connect(
    null,
    {
      createAccount
    }
  )
)
export default enhance(CreateAccountModal)
