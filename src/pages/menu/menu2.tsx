import { useEffect, useState } from 'react'

const Menu2 = function () {
  const [count, setCount] = useState<number>(1)
  console.log(`我是外层, count： ${count} `)
  useEffect(() => {
    setTimeout(() => {
      setCount(count + 1)
    }, 1000)
    console.log(`第二个参数: 不传值, 第 ${count} 次执行`)
  })
  return (
    <div>
      <div>Menu2</div>
      <div>count:{count}</div>
    </div>
  )
}
export default Menu2
