import React from 'react';
import MainLayout from './layout';
import './App.css';
import {ConfigProvider} from 'antd';



function App() {
  return (
    <ConfigProvider
    theme={{
      token: {
        colorPrimary: '#1677ff',
      },
    }}
  > <MainLayout/>
  </ConfigProvider>
  );
}

export default App;
