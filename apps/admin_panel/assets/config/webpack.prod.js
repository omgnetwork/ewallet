const webpack = require('webpack');
const merge = require('webpack-merge');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const baseConfig = require('./webpack.js');
const Dotenv = require('dotenv-webpack');

module.exports = merge(baseConfig, {
  devtool: 'source-map',
  plugins: [
    new UglifyJSPlugin({
      sourceMap: true,
    }),
    new webpack.DefinePlugin({
      // Intentionally set to 'production' and not 'prod' because this environment variable
      // is for node libraries to detect production environment.
      'process.env.NODE_ENV': JSON.stringify('production'),
    }),
    new Dotenv(),
  ],
});
