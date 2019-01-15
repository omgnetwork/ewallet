import React, { Component, PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import ExportFetcher from '../omg-export/exportFetcher'
import { downloadExportFileById, getExports } from '../omg-export/action'
import TopNavigation from '../omg-page-layout/TopNavigation'
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
import ConfirmationModal from '../omg-confirmation-modal'
import { Manager, Reference, Popper } from 'react-popper'

const Container = styled.div`
  position: relative;
  padding-bottom: 50px;
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
  background-color: white;
  width: 400px;
  z-index: 2;
  position: relative;
  > i {
    position: absolute;
    right: 25px;
    color: ${props => props.theme.colors.S500};
    top: 25px;
    cursor: pointer;
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
    color: ${props => (props.disabled ? props.theme.colors.S400 : props.theme.colors.B400)};
    :hover {
      background-color: ${props => props.theme.colors.BL400};
      color: white;
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
    a:hover {
      text-decoration: underline;
    }
  }
  td:first-child {
    max-width: 200px;
    white-space: nowrap;
    text-overflow: ellipsis;
    overflow: hidden;
  }
  .string-value {
    white-space: nowrap;
  }
`

const TitleContainer = styled.div`
  > i {
    cursor: pointer;
  }
`
const columns = [
  { key: 'filename', title: 'NAME' },
  { key: 'params_match_all', title: 'MATCH ALL' },
  { key: 'params_match_any', title: 'MATCH ANY' },
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
    history: PropTypes.object,
    exportTransaction: PropTypes.func,
    location: PropTypes.object,
    downloadExportFileById: PropTypes.func,
    getExports: PropTypes.func
  }
  state = { submitStatus: CONSTANT.LOADING_STATUS.DEFAULT, confirmationModalOpen: false }

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
  onClickExport = (fetch, confirm) => async e => {
    e.preventDefault()
    if (!this.state.fromDate && !this.state.toDate && !confirm) {
      this.setState({ confirmationModalOpen: true })
    } else {
      this.setState({ submitStatus: CONSTANT.LOADING_STATUS.PENDING, confirmationModalOpen: false })
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
  }
  closeConfirmationModal = e => {
    this.setState({ confirmationModalOpen: false, fromDate: '', toDate: '' })
  }
  onClickGenerate = e => {
    this.setState({ generateExportOpen: true })
  }
  onClickDownload = id => async e => {
    this.props.downloadExportFileById(id)
  }
  rowRenderer = (key, data, row) => {
    switch (key) {
      case 'created_at':
        return (
          <TimestampContainer>
            <span>{moment(row.created_at).format('ddd, DD/MM/YYYY hh:mm:ss')}</span>
            <Icon name='Download' onClick={this.onClickDownload(row)} />
          </TimestampContainer>
        )
      case 'filename':
        if (row.status === 'completed') {
          return <a onClick={this.onClickDownload(row)}>{`${row.schema}-${row.created_at}`}</a>
        } else if (row.status === 'processing' || row.status === 'new') {
          return (
            <div style={{ maxWidth: '450px' }}>
              <ProgressTextContainer>
                <span>Exporting...</span>
                <span>{row.completion.toFixed(2)}%</span>
              </ProgressTextContainer>
              <ProgressBar percentage={row.completion.toFixed(2)} />
            </div>
          )
        }
        return '-'
      case 'params_match_all':
        return row.params.match_all
          ? row.params.match_all.length
            ? row.params.match_all.map((query, i) => (
              <div style={{ whiteSpace: 'nowrap' }} key={i}>
                  [ {query.field} ] [ {query.comparator} :{' '}
                {moment(query.value).isValid()
                    ? moment(query.value).format('DD/MM/YYYY hh:mm:ss')
                    : query.value}{' '}
                  ]
                </div>
              ))
            : '-'
          : '-'

      case 'params_match_any':
        return row.params.match_any
          ? row.params.match_any.length
            ? row.params.match_any.map((query, i) => (
              <div style={{ whiteSpace: 'nowrap' }} key={i}>
                  [ {query.field} ] [ {query.comparator} :{' '}
                {moment(query.value).isValid()
                    ? moment(query.value).format('DD/MM/YYYY hh:mm:ss')
                    : query.value}{' '}
                  ]
                </div>
              ))
            : '-'
          : '-'

      default:
        return data
    }
  }
  onClickClose = e => {
    this.setState({ generateExportOpen: false })
  }
  renderExportButton (fetch) {
    return (
      <Manager>
        <Reference>
          {({ ref, style }) => (
            <div ref={ref} style={{ ...style, display: 'inline-block', marginLeft: '10px' }}>
              <Button styleType='primary' onClick={this.onClickGenerate}>
                <Icon name='Export' /> Generate
              </Button>
            </div>
          )}
        </Reference>
        {this.state.generateExportOpen && (
          <Popper
            placement='auto-end'
            eventsEnabled={false}
            place='below'
            modifiers={{ offset: { enabled: true, offset: 500 } }}
          >
            {({ ref, style, placement, arrowProps }) => (
              <div ref={ref} style={{ ...style, zIndex: 1 }} data-placement={placement}>
                <ExportFormContainer>
                  <Icon name='Close' onClick={this.onClickClose} />
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
                <div ref={arrowProps.ref} style={arrowProps.style} />
              </div>
            )}
          </Popper>
        )}
      </Manager>
    )
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
                <TopNavigation
                  title={
                    <TitleContainer>
                      <Icon name='Arrow-Left' onClick={this.props.history.goBack} /> Export
                      Transactions
                    </TitleContainer>
                  }
                  buttons={[this.renderExportButton(fetch)]}
                  secondaryAction={false}
                />
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

                <ConfirmationModal
                  open={this.state.confirmationModalOpen}
                  onRequestClose={this.closeConfirmationModal}
                  onOk={this.onClickExport(fetch, true)}
                >
                  <div style={{ marginBottom: '15px', padding: '15px' }}>
                    Leaving the fields empty will{' '}
                    <span style={{ color: 'red' }}>export all transactions</span>
                  </div>
                </ConfirmationModal>
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
