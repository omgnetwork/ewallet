import React from 'react';
import PropTypes from 'prop-types';
import { Button } from 'react-bootstrap';
import OMGTruncatedCell from './OMGTruncatedCell';
import tableConstants from '../constants/table.constants';
import { formatContent } from '../helpers/tableFormatter';

const OMGTableContentRow = ({ data }) => {
  const tds = Object.keys(data).map((key) => {
    const content = data[key];
    switch (content.type) {
      case tableConstants.PROPERTY: {
        const obj = formatContent(content.value);
        return (
          <td key={key} className={obj.className}>
            {content.shortened ?
              <OMGTruncatedCell content={obj.content} /> : obj.content
            }
          </td>
        );
      }
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
