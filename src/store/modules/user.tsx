import { PayloadAction, createAsyncThunk, createSlice } from '@reduxjs/toolkit'

// 初始化状态值的类型声明
export type UserStateType = {
  id: string | null
  name: string
  age: number
  phone: string
  status?: string
}

// 该业务的初始化状态值
const userState: UserStateType = {
  id: '01',
  name: '小明',
  age: 18,
  phone: '13006567656',
}

// 用户详情
type UserInfo = {
  userId: string
  userName: string
  userAge: number
  userPhone: string
}

// 模拟查询用户详情的接口
export function fetchUserInfoById(userId: string) {
  return new Promise<{ data: UserInfo }>((resolve) =>
    setTimeout(
      () =>
        resolve({
          data: {
            userId,
            userName: '模拟用户',
            userAge: 28,
            userPhone: '13006187657',
          },
        }),
      3000
    )
  )
}

// 处理异步操作
export const fetchUserInfoAsync = createAsyncThunk(
  'user/fetchUserInfoById',
  async (userId: string) => {
    const response = await fetchUserInfoById(userId)
    return response.data
  }
)

const user = createSlice({
  // 命名空间，name值会作为action type的前缀
  name: 'user',
  // 初始化状态
  initialState: userState,
  // 1.定义reducer更新状态函数  2.组件中dispatch使用的action函数
  reducers: {
    changeName: (state, action: PayloadAction<string>) => {
      state.name = action.payload
    },
    ChangeAge: (state, action: PayloadAction<number>) => {
      state.age = action.payload
    },
    exit(state, action: PayloadAction<string>) {
      if (state.id === action.payload) {
        state.id = null
      }
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchUserInfoAsync.pending, (state) => {
        state.status = 'loading'
      })
      .addCase(fetchUserInfoAsync.fulfilled, (state, action) => {
        state.status = 'idle'
        state.id = action.payload.userId
        state.name = action.payload.userName
        state.age = action.payload.userAge
        state.phone = action.payload.userPhone
      })
      .addCase(fetchUserInfoAsync.rejected, (state) => {
        state.status = 'failed'
      })
  },
})

// 导出action函数
export const { changeName, ChangeAge, exit } = user.actions

// 导出reducer,用与创建store
export default user.reducer
