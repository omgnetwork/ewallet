import React from 'react';
import PropTypes from 'prop-types';
import { Button } from 'react-bootstrap';
import numberWithCommas from '../helpers/numberFormatter';
import OMGTruncatedCell from './OMGTruncatedCell';
import tableConstants from '../constants/table.constants';

function formatValue(value) {
  switch (typeof value) {
    case 'object':
      return { content: value, className: 'omg-table-content-row__center' };
    case 'number':
      return { content: numberWithCommas(value), className: 'omg-table-content-row__right' };
    default:
      return { content: `${value}`, className: 'omg-table-content-row__left' };
  }
}

const OMGTableContentRow = ({ data }) => {
  const tds = Object.keys(data).map((key) => {
    const content = data[key];
    switch (content.type) {
      case tableConstants.PROPERTY: {
        const obj = formatValue(content.value);
        return (
          <td key={key} className={obj.className}>
            {content.shortened ?
              <OMGTruncatedCell content={obj.content} /> : obj.content
            }
          </td>
        ); }
      case tableConstants.ACTIONS:
        return (content.value.map(action => (
          <td key={action.title}>
            <Button
              key={action.title}
              bsStyle="link"
              className="link-omg-blue"
              onClick={() => action.callback(data.id.value)}
            >
              {action.title}
            </Button>
          </td>)));
      default: return (<div />);
    }
  });
  return (
    <tr>
      {tds}
    </tr>
  );
};

OMGTableContentRow.propTypes = {
  data: PropTypes.object.isRequired,
};

export default OMGTableContentRow;
