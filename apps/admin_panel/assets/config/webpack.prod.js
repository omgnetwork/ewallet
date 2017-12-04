const webpack = require("webpack");
const merge = require("webpack-merge");
const UglifyJSPlugin = require("uglifyjs-webpack-plugin");
const base_config = require("./webpack.js");

module.exports = merge(base_config, {
  devtool: "source-map",
  plugins: [
    new UglifyJSPlugin({
      sourceMap: true
    }),
    new webpack.DefinePlugin({
      // Intentionally set to 'production' and not 'prod' because this environment variable
      // is for node libraries to detect production environment.
      "process.env.NODE_ENV": JSON.stringify("production")
    })
  ]
});
