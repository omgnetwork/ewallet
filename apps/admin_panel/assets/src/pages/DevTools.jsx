import React from 'react';
import { createDevTools } from 'redux-devtools';
import LogMonitor from 'redux-devtools-log-monitor';
import DockMonitor from 'redux-devtools-dock-monitor';

export default createDevTools(<DockMonitor
  changePositionKey="ctrl-w"
  defaultIsVisible={false}
  toggleVisibilityKey="ctrl-h"
>
  <LogMonitor />
</DockMonitor>); // eslint-disable-line react/jsx-closing-tag-location
