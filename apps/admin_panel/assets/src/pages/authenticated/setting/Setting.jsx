import React from 'react';
import SettingForm from './SettingForm';
import SettingInvitation from './SettingInvitation';

export const INVITATION = {
  params: {
    email: 'email',
    token: 'token',
  },
  pathname: 'accept_invitation',
};

const Setting = () => (
  <div className="row">
    <div className="col-xs-12 col-sm-6">
      <div className="omg-form">
        <SettingForm />
        <div className="mb-1 mt-3" />
        <SettingInvitation invitation={INVITATION} />
      </div>
    </div>
  </div>
);

export default Setting;
