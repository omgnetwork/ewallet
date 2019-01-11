import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import ActivityLogProvider from '../omg-activity-log/ActivityLogProvider'
import { Icon } from '../omg-uikit'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
import { compose } from 'recompose'
import moment from 'moment'
const PanelContainer = styled.div`
  height: 100vh;
  position: fixed;
  right: 0;
  width: 560px;
  background-color: white;
  padding: 40px 30px;
  box-shadow: 0 0 15px 0 rgba(4, 7, 13, 0.1);
  > i {
    position: absolute;
    right: 25px;
    color: ${props => props.theme.colors.S500};
    top: 25px;
    cursor: pointer;
  }
`
const SubDetailTitle = styled.div`
  margin-top: 10px;
  color: ${props => props.theme.colors.B100};
  margin-bottom: 10px;
  > span {
    padding: 0 5px;
    :first-child {
      padding-left: 0;
    }
  }
`

const enhance = compose(withRouter)
class TransactionRequestPanel extends Component {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object,
    match: PropTypes.object
  }

  constructor (props) {
    super(props)
    this.state = {}
  }
  onClickClose = () => {
    const searchObject = queryString.parse(this.props.location.search)
    delete searchObject['show-activity-tab']
    this.props.history.push({
      search: queryString.stringify(searchObject)
    })
  }
  render () {
    return (
      <ActivityLogProvider
        activityId={queryString.parse(this.props.location.search)['show-activity-tab']}
        render={({ activity }) => {
          console.log(activity)
          return (
            <PanelContainer>
              <Icon name='Close' onClick={this.onClickClose} />
              <h4>{activity.originator_type} | {activity.action} | {moment(activity.created_at).format('ddd, DD/MM/YYYY hh:mm:ss')}</h4>
              <SubDetailTitle>
                <span>{activity.id}</span> | <span>{activity.action}</span>
              </SubDetailTitle>
              {JSON.stringify(activity.target_changes)}
            </PanelContainer>
          )
        }}
      />
    )
  }
}

export default enhance(TransactionRequestPanel)
