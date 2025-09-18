import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo);
    this.setState({
      error: error,
      errorInfo: errorInfo
    });
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: '20px', border: '2px solid red', margin: '10px' }}>
          <h2>コンポーネントエラーが発生しました</h2>
          <details style={{ whiteSpace: 'pre-wrap' }}>
            <summary>エラー詳細</summary>
            <p><strong>エラー:</strong> {this.state.error && this.state.error.toString()}</p>
            <p><strong>スタックトレース:</strong></p>
            <pre>{this.state.errorInfo.componentStack}</pre>
          </details>
          <button onClick={() => window.location.reload()}>
            ページを再読み込み
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;