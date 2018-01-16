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
    const { headers, shortenedColumnIds } = this.props;
    const tableHeaders = Object.keys(headers).map(key =>
      (<OMGTableHeader
        key={key}
        handleClick={this.onSort}
        id={key}
        sortDirection={key === by ? dir : 'default'}
        title={headers[key]}
      />));
    const { contents } = this.props;

    const datas = contents.map(data =>
      (<OMGTableContentRow
        key={data.id}
        data={data}
        shortenedColumnIds={shortenedColumnIds}
      />));

    return (
      <Table responsive>
        <thead>
          <tr>
            {tableHeaders}
          </tr>
        </thead>
        <tbody>
          {datas}
        </tbody>
      </Table>
    );
  }
}

OMGTable.defaultProps = {
  shortenedColumnIds: [],
};

OMGTable.propTypes = {
  contents: PropTypes.array.isRequired,
  headers: PropTypes.objectOf(PropTypes.string).isRequired,
  shortenedColumnIds: PropTypes.arrayOf(PropTypes.string),
  sort: PropTypes.object.isRequired,
  updateSorting: PropTypes.func.isRequired,
};

export default OMGTable;
