const webpack = require('webpack');
const baseConfig = require('./webpack.js');
const merge = require('webpack-merge');
const path = require('path');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const Dotenv = require('dotenv-webpack');

module.exports = merge(baseConfig, {
  devtool: 'inline-source-map',
  devServer: {
    contentBase: path.resolve(__dirname, './public'),
    historyApiFallback: true, // Fallback to the root index when resource is not found.
    quiet: true, // webpack-dev-server is extremely noisy, let's hush it
  },
  plugins: [
    new UglifyJSPlugin({
      sourceMap: true,
    }),
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify('develop'),
    }),
    new Dotenv(),
  ],
});
