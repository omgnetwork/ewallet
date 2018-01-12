import React from 'react';
import { storiesOf } from '@storybook/react';
import { Table } from 'react-bootstrap';
import OMGTableContentRow from '../../src/components/OMGTableContentRow';

const container = {
  width: '500px',
  paddingLeft: '2rem',
};

const smallContainer = story => (
  <div style={container}>
    {story()}
  </div>
);

storiesOf('OMGTableContentRow', module)
  .addDecorator(smallContainer)
  .add('object with 1 number and 2 strings', () => {
    const data = {
      id: 1,
      name: 'OmiseGO',
      description: 'Test',
    };

    return (
      <Table responsive>
        <thead>
          <tr>
            <th>
              Id
            </th>
            <th>
              Name
            </th>
            <th>
              Description
            </th>
          </tr>
        </thead>
        <tbody>
          <OMGTableContentRow data={data} />
        </tbody>
      </Table>
    );
  })
  .add('object with 2 numbers, 1 boolean, and 2 strings', () => {
    const data = {
      id: 1,
      name: 'OmiseGO',
      description: 'Test',
      master: true,
      value: 8.99,
    };

    return (
      <Table responsive>
        <thead>
          <tr>
            <th>
              Id
            </th>
            <th>
              Name
            </th>
            <th>
              Description
            </th>
            <th>
              Master
            </th>
            <th>
              Value
            </th>
          </tr>
        </thead>
        <tbody>
          <OMGTableContentRow data={data} />
        </tbody>
      </Table>
    );
  });
