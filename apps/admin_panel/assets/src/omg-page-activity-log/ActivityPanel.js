import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import ActivityLogProvider from '../omg-activity-log/ActivityLogProvider'
import { Icon } from '../omg-uikit'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
import { compose } from 'recompose'
import moment from 'moment'
import Link from '../omg-links'
const PanelContainer = styled.div`
  height: 100vh;
  position: fixed;
  right: 0;
  width: 560px;
  background-color: white;
  padding: 40px 30px;
  box-shadow: 0 0 15px 0 rgba(4, 7, 13, 0.1);
  overflow: scroll;
  > i {
    position: absolute;
    right: 25px;
    color: ${props => props.theme.colors.S500};
    top: 25px;
    cursor: pointer;
  }
  h5 {
    margin-bottom: 10px;
    padding-top: 25px;
    letter-spacing: 1px;
    background-color: ${props => props.theme.colors.S300};
    display: inline-block;
    padding: 5px 10px;
  }
`
const SubDetailTitle = styled.div`
  margin-top: 10px;
  color: ${props => props.theme.colors.B100};
  padding-bottom: 25px;
  margin-bottom: 25px;
  border-bottom: 1px solid ${props => props.theme.colors.S400};
  > span {
    padding: 0 5px;
    vertical-align: middle;
    :first-child {
      padding-left: 0;
    }
  }
`

const InformationItem = styled.div`
  color: ${props => props.theme.colors.B200};
  display: flex;
  :not(:last-child) {
    margin-bottom: 10px;
  }
  b {
    white-space: nowrap;
  }
  span {
    word-break: break-word;
  }
  .colon {
    padding: 0 5px;
  }
`
const ChangesContainer = styled.div`
  border-top: 1px solid ${props => props.theme.colors.S400};
  padding-top: 25px;
  margin-top: 25px;
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
  getLink (type, id) {
    switch (type) {
      case 'wallet':
        return <Link to={`/wallets/${id}`}>{id}</Link>
      case 'account':
        return <Link to={`/accounts/${id}`}>{id}</Link>
      case 'user':
        return <Link to={`/users/${id}`}>{id}</Link>
      case 'token':
        return <Link to={`/tokens/${id}`}>{id}</Link>
      case 'transaction':
        const query = {
          ...queryString.parse(this.props.location.search),
          'show-transaction-tab': id
        }
        return (
          <Link
            to={{
              search: queryString.stringify(query)
            }}
          >
            {id}
          </Link>
        )
      default:
        return id
    }
  }
  renderChanges (activity) {
    return Object.keys(activity.target_changes).map(key => {
      if (activity.target_type === 'setting') {
        if (key === 'data') {
          return (
            <InformationItem key={key}>
              <b> {_.startCase(_.toLower(activity.target.key))}</b>{' '}
              <span className='colon'> : </span>
              <span>{activity.target_changes[key].value}</span>
            </InformationItem>
          )
        }
      }
      return (
        <InformationItem key={key}>
          <b> {_.startCase(_.toLower(key))}</b> <span className='colon'> : </span>
          <span>{JSON.stringify(activity.target_changes[key]).replace(/"/g, '')}</span>
        </InformationItem>
      )
    })
  }
  render () {
    return (
      <ActivityLogProvider
        activityId={queryString.parse(this.props.location.search)['show-activity-tab']}
        render={({ activity }) => {
          return activity ? (
            <PanelContainer>
              <Icon name='Close' onClick={this.onClickClose} />
              <h4>
                {_.upperFirst(activity.action)} : {_.upperFirst(activity.target_type)}
              </h4>
              <SubDetailTitle>
                <span>{activity.id}</span>|<span>{activity.action}</span>|
                <span>{moment(activity.created_at).format('ddd, DD/MM/YYYY hh:mm:ss')}</span>
              </SubDetailTitle>
              <div>
                <InformationItem>
                  <b> Originator</b>
                  <span className='colon'> : </span>
                  <span>
                    {activity.originator
                      ? this.getLink(
                          activity.originator_type,
                          activity.originator.id || activity.originator.address
                        )
                      : '-'}
                  </span>
                </InformationItem>
                <InformationItem>
                  <b>Originator Type</b>
                  <span className='colon'> : </span>
                  <span>{_.startCase(activity.originator_type)}</span>
                </InformationItem>
                <InformationItem>
                  <b>Action</b>
                  <span className='colon'> : </span>
                  <span>{_.startCase(activity.action)}</span>
                </InformationItem>
                <InformationItem>
                  <b>Target</b>
                  <span className='colon'> : </span>
                  <span>
                    {' '}
                    {activity.target
                      ? this.getLink(
                          activity.target_type,
                          activity.target.id || activity.target.address
                        )
                      : '-'}
                  </span>
                </InformationItem>
                <InformationItem>
                  <b>Target Type</b>
                  <span className='colon'> : </span>
                  <span>{_.startCase(activity.target_type)}</span>
                </InformationItem>
                {activity.target_type === 'setting' && (
                  <InformationItem>
                    <b>Configuration Key</b>
                    <span className='colon'> : </span>
                    <span>{_.startCase(activity.target.key)}</span>
                  </InformationItem>
                )}
                <InformationItem>
                  <b>Timestamp</b>
                  <span className='colon'> : </span>
                  <span>{moment(activity.created_at).format('ddd, DD/MM/YYYY hh:mm:ss')}</span>
                </InformationItem>
              </div>
              <ChangesContainer>
                <h5>Changes</h5>
                {this.renderChanges(activity)}
              </ChangesContainer>
            </PanelContainer>
          ) : null
        }}
      />
    )
  }
}

export default enhance(TransactionRequestPanel)
