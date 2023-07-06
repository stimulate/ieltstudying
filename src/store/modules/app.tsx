import { PayloadAction, createSlice } from '@reduxjs/toolkit'
import { MenuTheme } from 'antd/es/menu/MenuContext'

export type AppStateType = {
  title: string
  theme: MenuTheme
}

const appState: AppStateType = {
  title: '应用名称',
  theme: 'dark',
}

const app = createSlice({
  // 命名空间，name值会作为action type的前缀
  name: 'app',
  // 初始化状态
  initialState: appState,
  // 1.定义reducer更新状态函数  2.组件中dispatch使用的action函数
  reducers: {
    changeTitle: (state, action: PayloadAction<string>) => {
      state.title = action.payload
    },
    changeTheme: (state, action: PayloadAction<string>) => {
      state.theme = action.payload as MenuTheme
    },
  },
})

// 导出action函数
export const { changeTitle, changeTheme } = app.actions

// 导出reducer,用与创建store
export default app.reducer
