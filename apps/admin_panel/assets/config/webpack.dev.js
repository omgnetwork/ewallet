const webpack = require('webpack');
const baseConfig = require('./webpack.js');
const merge = require('webpack-merge');
const path = require('path');
const Dotenv = require('dotenv-webpack');

module.exports = merge(baseConfig, {
  devtool: 'inline-source-map',
  // According to webpack's docs: "Watching does not work with NFS
  // and machines in VirtualBox." Since we use VirtualBox in Goban
  // to setup dev machines, we need to use polling instead to watch
  // for file changes. See: https://webpack.js.org/configuration/watch/
  watchOptions: {
    poll: 1000,
    ignored: /node_modules/,
  },
  plugins: [
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify('develop'),
    }),
    new Dotenv(),
  ],
});
