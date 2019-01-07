import React, { Component, PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import ExportFetcher from '../omg-export/exportFetcher'
import { downloadExportFileById, getExports } from '../omg-export/action'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'
import { Input, Button, Icon } from '../omg-uikit'
import DateTime from 'react-datetime'
import { connect } from 'react-redux'
import { exportTransaction } from '../omg-transaction/action'
import { createSearchTransactionExportQuery } from './searchField'
import queryString from 'query-string'
import moment from 'moment'
import CONSTANT from '../constants'
import ProgressBar from './ProgressBar'
const Container = styled.div`
  position: relative;
  padding-bottom: 50px;
  }
`
const DetailContainer = styled.div`
  display: flex;
  > div {
    flex: 1 1 auto;
  }
  > div:first-child {
    max-width: 400px;
    padding-right: 20px;
  }
`
const FormDetailContainer = styled.form`
  border: 1px solid #ebeff7;
  border-radius: 2px;
  padding: 40px;
  box-shadow: 0 4px 12px 0 #e8eaed;
  input {
    width: 100%;
  }
  > div:first-child {
    margin-bottom: 20px;
  }
  h5 {
    text-align: left;
  }
  text-align: right;
`

const ExportFormContainer = styled.div`
  button {
    margin-top: 20px;
    padding-left: 40px;
    padding-right: 40px;
  }
`
const TimestampContainer = styled.div`
  display: flex;
  align-items: center;
  > span {
    flex: 1 1 auto;
    margin-right: 5px;
    white-space: nowrap;
  }
  i {
    margin-left: auto;
    padding: 5px;
    border: 1px solid ${props => props.theme.colors.S400};
    border-radius: 4px;
    display: block;
    color: ${props => (props.disabled ? props.theme.colors.S400 : props.theme.colors.B400)};
    :hover {
      background-color: ${props => props.disabled ? 'inherit' : props.theme.colors.BL400};
      color: ${props => (props.disabled ? props.theme.colors.S400 : 'white')};
      cursor: ${props => (props.disabled ? 'auto' : 'pointer')};
    }
  }
`
const ProgressTextContainer = styled.div`
  display: flex;
  margin-bottom: 5px;
  font-size: 12px;
  > span:first-child {
    flex: 1 1 auto;
  }
  > span:last-child {
    margin-left: auto;
  }
`

const TableContainer = styled.div`
  td:nth-child(2) {
    width: 190px;
  }
  td {
    height: 50px;
  }
  td:first-child {
    width: 50%;
  }
  td {
    cursor: auto;
  }
`
const columns = [
  { key: 'params', title: 'QUERY' },
  { key: 'status', title: 'STATUS' },
  { key: 'created_at', title: 'CREATED DATE' }
]

const enhance = compose(
  withRouter,
  connect(
    null,
    {
      exportTransaction,
      downloadExportFileById,
      getExports
    }
  )
)
class TransactionExportPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    exportTransaction: PropTypes.func,
    location: PropTypes.object,
    downloadExportFileById: PropTypes.func,
    getExports: PropTypes.func
  }
  state = { submitStatus: CONSTANT.LOADING_STATUS.DEFAULT }

  componentDidMount = () => {
    this._pollingExport = setInterval(() => {
      this.props.getExports({
        page: queryString.parse(this.props.location.search)['page'],
        perPage: 10
      })
    }, 3000)
  }

  componentWillUnmount () {
    clearInterval(this._pollingExport)
  }

  onDateTimeFromChange = date => {
    if (date.format) this.setState({ fromDate: date })
  }
  onDateTimeFromFocus = e => {
    this.setState({ fromDate: '', fromDateFocus: true })
  }
  onDateTimeToChange = date => {
    if (date.format) this.setState({ toDate: date })
  }
  onDateTimeToFocus = e => {
    this.setState({ toDate: '' })
  }
  onClickExport = fetch => async e => {
    e.preventDefault()
    this.setState({ submitStatus: CONSTANT.LOADING_STATUS.PENDING })
    try {
      const query = createSearchTransactionExportQuery({
        fromDate: this.state.fromDate,
        toDate: this.state.toDate
      })
      const result = await this.props.exportTransaction(query)
      if (result.data) {
        this.setState({
          submitStatus: CONSTANT.LOADING_STATUS.SUCCESS
        })
        fetch()
      } else {
        this.setState({
          submitStatus: CONSTANT.LOADING_STATUS.FAILED
        })
      }
    } catch (error) {
      this.setState({ submitStatus: CONSTANT.LOADING_STATUS.FAILED })
    }
  }

  onClickDownload = id => async e => {
    this.props.downloadExportFileById(id)
  }

  rowRenderer = (key, data, row) => {
    switch (key) {
      case 'created_at':
        return (
          <TimestampContainer disabled={row.completion < 100}>
            <span>{moment(row.created_at).format('ddd, DD/MM/YYYY hh:mm:ss')}</span>
            <Icon
              name='Download'
              onClick={this.onClickDownload(row)}
            />
          </TimestampContainer>
        )
      case 'params':
        if (row.status === 'completed') {
          return (
            <div>
              <div>start: {moment(data.match_all[0].value).format('ddd, DD/MM/YYYY hh:mm:ss')}</div>
              <div>end: {moment(data.match_all[1].value).format('ddd, DD/MM/YYYY hh:mm:ss')}</div>
            </div>
          )
        } else if (row.status === 'processing' || row.status === 'new') {
          return (
            <div style={{ maxWidth: '450px' }}>
              <ProgressTextContainer>
                <span>Exporting...</span>
                <span>{row.completion.toFixed(0)}%</span>
              </ProgressTextContainer>
              <ProgressBar percentage={row.completion.toFixed(2)} />
            </div>
          )
        }

      default:
        return data
    }
  }

  render () {
    return (
      <Container>
        <ExportFetcher
          query={{
            page: queryString.parse(this.props.location.search)['page'],
            perPage: 10
          }}
          render={({ data, individualLoadingStatus, pagination, fetch }) => {
            return (
              <div>
                <DetailLayout backPath={`/${this.props.match.params.accountId}/transaction`}>
                  <TopBar
                    title={'Export'}
                    breadcrumbItems={['Transaction', 'export']}
                    buttons={[]}
                  />
                </DetailLayout>
                <DetailContainer>
                  <ExportFormContainer>
                    <FormDetailContainer onSubmit={this.onClickExport(fetch)}>
                      <div>
                        <h5>From Date</h5>
                        <DateTimeHotFix
                          onChange={this.onDateTimeFromChange}
                          onFocus={this.onDateTimeFromFocus}
                          value={this.state.fromDate}
                          placeholder='From date..'
                        />
                      </div>
                      <div>
                        <h5>To Date</h5>
                        <DateTimeHotFix
                          onChange={this.onDateTimeToChange}
                          onFocus={this.onDateTimeToFocus}
                          value={this.state.toDate}
                          placeholder='To date..'
                        />
                      </div>
                      <Button loading={this.state.submitStatus === CONSTANT.LOADING_STATUS.PENDING}>
                        Export
                      </Button>
                    </FormDetailContainer>
                  </ExportFormContainer>
                  <TableContainer>
                    <SortableTable
                      rows={data}
                      columns={columns}
                      loadingStatus={individualLoadingStatus}
                      isFirstPage={pagination.is_first_page}
                      isLastPage={pagination.is_last_page}
                      navigation
                      rowRenderer={this.rowRenderer}
                      loadingEffect={false}
                    />
                  </TableContainer>
                </DetailContainer>
              </div>
            )
          }}
        />
      </Container>
    )
  }
}

class DateTimeHotFix extends PureComponent {
  static propTypes = {
    onChange: PropTypes.func,
    value: PropTypes.object,
    onFocus: PropTypes.func,
    placeholder: PropTypes.string
  }
  render () {
    return (
      <DateTime
        ref='picker'
        closeOnSelect
        onChange={this.props.onChange}
        renderInput={(props, openCalendar, closeCalendar) => {
          return (
            <Input
              {...props}
              value={this.props.value && this.props.value.format('DD/MM/YYYY hh:mm:ss a')}
              onFocus={this.props.onFocus}
              normalPlaceholder={this.props.placeholder}
              closeOnSelect
            />
          )
        }}
      />
    )
  }
}

export default enhance(TransactionExportPage)
