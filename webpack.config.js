// plugins/redmine_release_kanban/webpack.config.js
const path = require("path");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = {
  mode: "development", // or 'production'
  entry: "./assets/javascripts/kanban/index.jsx",
  output: {
    filename: "kanban_bundle.js",
    path: path.resolve(__dirname, "assets/javascripts/kanban/dist"),
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
          from: path.resolve(__dirname, "assets/javascripts/kanban/dist/kanban_bundle.js"),
          to: "/usr/src/redmine/public/plugin_assets/redmine_release_kanban/kanban_bundle.js",
        },
      ],
    }),
  ],
};
