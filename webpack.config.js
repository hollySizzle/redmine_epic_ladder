// plugins/redmine_react_gantt_chart/webpack.config.js
const path = require("path");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = {
  mode: "development", // or 'production'
  entry: "./assets/javascripts/react_gantt_chart/index.jsx",
  output: {
    filename: "bundle.js",
    path: path.resolve(__dirname, "assets/javascripts/react_gantt_chart/dist"),
  },
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
          options: {
            presets: ["@babel/preset-env", "@babel/preset-react"],
          },
        },
      },
      {
        test: /\.css$/,
        use: [
          "style-loader",
          "css-loader",
          {
            loader: "postcss-loader",
            options: {
              postcssOptions: {
                plugins: [require("tailwindcss"), require("autoprefixer")],
              },
            },
          },
        ],
      },
      {
        test: /\.scss$/,
        use: [
          "style-loader",
          "css-loader",
          {
            loader: "postcss-loader",
            options: {
              postcssOptions: {
                plugins: [require("tailwindcss"), require("autoprefixer")],
              },
            },
          },
          "sass-loader",
        ],
      },
    ],
  },
  ignoreWarnings: [/Failed to parse source map/],
  resolve: {
    extensions: [".js", ".jsx"],
    alias: {
      'tailwindcss/version.js': false,
    },
  },
  plugins: [
    new CopyWebpackPlugin({
      patterns: [
        {
          from: path.resolve(__dirname, "assets/javascripts/react_gantt_chart/dist/bundle.js"),
          to: "/usr/src/redmine/public/plugin_assets/redmine_react_gantt_chart/bundle.js",
        },
      ],
    }),
  ],
};
