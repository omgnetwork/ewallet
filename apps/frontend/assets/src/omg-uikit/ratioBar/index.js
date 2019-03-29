import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
const RatioBarContainer = styled.div`
  width: 100%;
  position: relative;
`
const TransactionBar = styled.div`
  position: relative;
  height: 25px;
  background-color: ${props => props.theme.colors.S300};
  margin-top: 15px;
`
const BoxRatio = styled.div`
  height: 10px;
  width: 10px;
  display: inline-block;
  margin-right: 5px;
  background-color: ${props => props.color};
`
const RatioBarDetailContainer = styled.div`
  margin-top: 20px;
  display: flex;
  align-items: flex-end;
`
const BarItem = styled.div`
    display: inline-block;
    height: 100%;
    width: ${props => `${props.width}%`};
    background-color: ${props => props.color};
`
const RatioDetailItem = styled.div`
  :not(:last-child) {
    margin-right: 20px;
    margin-left: auto;
  }
  :first-child {
    flex: 1 1 auto;
    font-size: 10px;
    color: ${props => props.theme.colors.B100};
    letter-spacing: 1px;
    font-weight: 600;
  }
`
export default class RatioBar extends Component {
  static propTypes = {
    rows: PropTypes.array.isRequired,
    title: PropTypes.string
  }
  renderBar = () => {
    return (
      <TransactionBar>
        {this.props.rows.map((d, i) => (
          <BarItem width={d.percent} color={d.color} key={i} />
      ))}
      </TransactionBar>
    )
  }
  renderExplaination = () => {
    return (
      <RatioBarDetailContainer>
        <RatioDetailItem>{this.props.title}</RatioDetailItem>
        {this.props.rows.map((d, i) => (
          <RatioDetailItem key={i}>
            <BoxRatio color={d.color} /> <span>{d.content}</span>
          </RatioDetailItem>
       ))}
      </RatioBarDetailContainer>
    )
  }

  render () {
    return (
      <RatioBarContainer>
        {this.renderExplaination()}
        {this.renderBar()}
      </RatioBarContainer>
    )
  }
}
