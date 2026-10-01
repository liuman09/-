# 项目技术规范

## 技术栈

- 前端: React 19 + TypeScript
- 构建: Vite 8（rolldown）
- 样式: Tailwind CSS v4
- UI 组件: shadcn/ui `import { Button } from "@/components/ui/button";`
- 图标: lucide-react `import { SearchIcon } from "lucide-react";`
- 图表: echarts 6 **按需注册** + echarts-for-react（见下方"图表用法"）
- 动画: framer-motion `import { motion } from "framer-motion";`
- 路由: react-router-dom v7 `import { Link, useNavigate } from "react-router-dom";`
- 提示: sonner（`<Toaster/>` 已在 `src/index.tsx` 挂载，直接 `import { toast } from "sonner"`）

### 图表用法

只注册折线图所需模块，避免全量 echarts 进 bundle；入口必须用 **esm/core**（CJS 的 `lib/core` 在 rolldown 下 default 导出 interop 异常）：

```typescript
import ReactEChartsCore from "echarts-for-react/esm/core";
import * as echarts from "echarts/core";
import { LineChart } from "echarts/charts";
import { GridComponent, TooltipComponent, LegendComponent, MarkLineComponent } from "echarts/components";
import { CanvasRenderer } from "echarts/renderers";

echarts.use([LineChart, GridComponent, TooltipComponent, LegendComponent, MarkLineComponent, CanvasRenderer]);

<ReactEChartsCore echarts={echarts} option={option} className="h-[240px]" />
```

> 不要使用未注册的主题名（如 `theme="ud"`）；新增图表类型时在 `echarts.use([...])` 中补注册对应 Chart/Component。

---

## 目录结构

```
src/
├── index.tsx            # 入口（Provider + Toaster，勿修改）
├── app.tsx              # 路由配置（非首屏页面用 React.lazy 分包）
├── index.css            # 全局样式 + 主题变量
├── components/          # 跨页面业务组件 + 基础 UI
│   ├── Layout.tsx       # 全局布局容器（含 <Outlet />）
│   ├── game/            # 游戏化组件（HUD/警告/终态遮罩、成就墙）
│   └── ui/              # shadcn/ui 内置组件（勿修改）
├── pages/               # 页面模块（每个页面一个目录）
│   ├── ProductList/     # 世界总览（首页 /，多店铺+商品行+建店引导+员工弹窗）
│   ├── SandboxDashboard/# 商品沙盘详情（/product/:id）
│   ├── Report/          # 全屏周报（/report/:week）
│   ├── Settlement/      # 通关/破产/清算结算页（/settlement）
│   └── NotFoundPage/
├── engine/              # v2 纯函数引擎层（禁止依赖 React / 事件池配置）
│   ├── types.ts         # 世界/店铺/商品/快照/留痕等全部类型
│   ├── advanceWorld.ts  # 每周推进九步主流程
│   ├── computeProductWeek.ts / resolveParams.ts / effects.ts  # 单 SKU 周计算与参数解析
│   ├── ledger.ts        # 应收/应付账期、多币种折算
│   ├── inventory.ts     # 在途批次、库容
│   ├── reputation.ts    # 信誉度
│   ├── eventScheduler.ts# 事件掷取/生效/过期
│   ├── gameEvaluation.ts# 四关 / 8 成就 / 失败三态判定
│   ├── bossAdjust.ts    # 老板六组调整 + 留痕
│   ├── worldFactory.ts  # 世界/店铺/商品工厂与第 0 周蓝图
│   └── storageV2.ts     # 版本化 localStorage（含 v1 迁移链）
├── config/              # 纯数据配置（引擎计算文件禁止硬编码这些数字）
│   ├── markets.ts       # 国内/跨境两套市场规则
│   ├── platforms.ts     # 9 个平台及对市场规则的覆盖
│   ├── employees.ts     # 客服/运营/仓储三岗工资与加成
│   ├── gameGoals.ts     # 闯关四关
│   ├── achievements.ts  # 8 个成就
│   ├── reportNarratives.ts # 周报人情叙事模板
│   └── events/          # 事件池（macro/platform/industry/store/product 五类）
├── adapters/            # 引擎数据 → 页面视图模型
├── hooks/               # 自定义 Hooks（useWorld 为全局世界单例 store）
├── data/                # 知识卡片/术语等静态演示数据
├── utils/               # v1 遗留公式与单店逻辑（仅供迁移引用，勿在新代码使用）
└── lib/                 # 工具函数（cn() 等）

shared/
└── static/              # 静态资源
    ├── data/            # 数据文件（JSON）
    └── images/          # 图片资源

scripts/
├── typecheck.cjs        # tsc -p tsconfig.app.json（固定 node 路径）
└── engine-checks/       # 引擎纯函数断言脚本（run-check.cjs <name>-check）
```

### 分层约束

- `engine/` 全部为纯函数，不依赖 React、不直接 import 事件池等 config 数据（除显式允许的市场/平台/员工/事件定义读取点）
- 被引擎检查脚本引用的链路**禁止使用 `@/` 别名**，必须相对路径导入
- 新增/调整引擎规则时同步在 `scripts/engine-checks/` 补断言

---

## 当前路由

| 路径 | 页面 | 加载方式 |
|------|------|---------|
| `/` | 世界总览 ProductList | eager（首屏） |
| `/product/:id` | 商品沙盘 SandboxDashboard | lazy |
| `/report/:week` | 全屏周报 WeeklyReport | lazy |
| `/settlement` | 结算页 Settlement | lazy |
| `*` | NotFoundPage | lazy |

`BrowserRouter` 已在 `index.tsx` 配置，`app.tsx` 中**禁止**再包裹 Router；`Suspense` fallback 已在 `app.tsx` 提供骨架屏。

---

## 禁止修改的文件

| 文件 | 原因 |
|------|------|
| `src/index.tsx` | Provider 层级 + Toaster + 样式引入，由模板管理 |
| `src/components/ui/*` | shadcn/ui 内置组件，版本锁定 |

---

## 文件放置规则

| 内容类型 | 放置位置 |
|---------|---------|
| 新页面 | `src/pages/<PageName>/PageName.tsx` |
| 页面专属组件 | `src/pages/<PageName>/components/`（本项目部分弹窗与页面同目录，如 `pages/ProductList/`） |
| 跨页面业务组件 | `src/components/` |
| 纯计算/业务规则 | `src/engine/`（纯函数，配断言脚本） |
| 可调数值与文案配置 | `src/config/` |
| 自定义 Hooks | `src/hooks/` |
| 工具函数 | `src/lib/` |
| 静态数据文件 | `shared/static/data/` |
| 静态图片 | `shared/static/images/` |

---

## 导入路径

```typescript
// @/ 别名 → src/
import { cn } from "@/lib/utils";
import { useIsMobile } from "@/hooks/use-mobile";

// @shared/ 别名 → shared/
import heroImage from "@shared/static/images/hero.png";
import configData from "@shared/static/config.json";
```

---

## 主题变量

主题色定义在 `src/index.css`，通过 `:root` CSS 变量 + `@theme inline` 注册到 Tailwind。

| 用途 | Tailwind 类 | CSS 变量 |
|------|------------|----------|
| 页面背景 | `bg-background` | `--background` |
| 主文本 | `text-foreground` | `--foreground` |
| 卡片背景 | `bg-card` | `--card` |
| 次要文本 | `text-muted-foreground` | `--muted-foreground` |
| 主色 | `bg-primary` / `text-primary` | `--primary` |
| 强调色 | `bg-accent` | `--accent` |
| 边框 | `border-border` | `--border` |
| 危险色 | `text-destructive` | `--destructive` |
| 图表色 | `bg-chart-1` ~ `bg-chart-5` | `--chart-1` ~ `--chart-5` |

HSL 格式使用**空格分隔**：`--primary: hsl(150 60% 40%);`
