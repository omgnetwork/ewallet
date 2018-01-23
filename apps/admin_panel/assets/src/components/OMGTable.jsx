import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { Table } from 'react-bootstrap';
import OMGTableHeader from './OMGTableHeader';
import OMGTableContentRow from './OMGTableContentRow';

class OMGTable extends Component {
  constructor(props) {
    super(props);
    const sort = { by: 'id', dir: 'asc' };
    this.state = (sort);
    this.onSort = this.onSort.bind(this);
  }

  componentWillReceiveProps(nextProps) {
    this.setState(nextProps.sort);
  }

  onSort(by, dir) {
    this.setState(
      { by, dir },
      () => {
        const { updateSorting } = this.props;
        updateSorting({ by, dir });
      },
    );
  }

  render() {
    const { by, dir } = this.state;
    const { headers, content } = this.props;
    const tableHeaders = Object.keys(headers).map((key) => {
      const header = headers[key];
      return (<OMGTableHeader
        key={key}
        handleClick={this.onSort}
        id={key}
        sortable={header.sortable}
        sortDirection={key === by ? dir : 'default'}
        title={header.title}
      />);
    });
    const tableContent = content.map(row => (
      <OMGTableContentRow
        key={row.id.value}
        data={row}
      />
    ));
    return (
      <Table responsive>
        <thead>
          <tr>
            {tableHeaders}
          </tr>
        </thead>
        <tbody>
          {tableContent}
        </tbody>
      </Table>
    );
  }
}

OMGTable.propTypes = {
  content: PropTypes.array.isRequired,
  headers: PropTypes.object.isRequired,
  sort: PropTypes.object.isRequired,
  updateSorting: PropTypes.func.isRequired,
};

export default OMGTable;
