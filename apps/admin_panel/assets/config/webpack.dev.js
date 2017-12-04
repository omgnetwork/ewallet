const base_config = require("./webpack.js");
const merge = require("webpack-merge");
const path = require("path");

module.exports = merge(base_config, {
  devtool: "inline-source-map",
  devServer: {
    contentBase: path.resolve(__dirname, "./public"),
    historyApiFallback: true, // Fallback to the root index when resource is not found.
    quiet: true // webpack-dev-server is extremely noisy, let's hush it
  }
});
