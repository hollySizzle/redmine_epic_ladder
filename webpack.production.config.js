// plugins/redmine_react_gantt_chart/webpack.production.config.js
const path = require("path");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");

module.exports = {
  mode: "production",
  entry: "./assets/javascripts/react_gantt_chart/index.jsx",
  output: {
    filename: "bundle.js",
    path: path.resolve(__dirname, "assets/javascripts/react_gantt_chart/dist"),
    clean: true,
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
  resolve: {
    extensions: [".js", ".jsx"],
    alias: {
      'tailwindcss/version.js': false,
    },
  },
  optimization: {
    minimize: true,
    minimizer: [
      new TerserPlugin({
        terserOptions: {
          compress: {
            drop_console: true,
            drop_debugger: true,
            pure_funcs: ["console.log", "console.info", "console.debug"],
          },
          mangle: {
            safari10: true,
          },
          format: {
            comments: false,
          },
        },
        extractComments: false,
      }),
    ],
    // splitChunksは無効化（単一バンドルを維持）
  },
  performance: {
    hints: "warning",
    maxEntrypointSize: 512000,
    maxAssetSize: 512000,
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