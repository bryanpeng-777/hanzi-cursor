下面列出的 TDesign 组件已提供可直接使用的组件。

## 1. 桌面端组件

- 基础组件：`button` / `icon` / `image-viewer` / `link` / `typography`
- 布局组件：`descriptions` / `divider` / `empty` / `grid` / `guide` / `layout` / `space`
- 导航组件：`affix` / `anchor` / `breadcrumb` / `dropdown` / `menu` / `pagination` / `steps` / `sticky-tool` / `tabs`
- 表单组件：`auto-complete` / `cascader` / `checkbox` / `color-picker` / `date-picker` / `form` / `input-adornment` / `input-number` / `input` / `radio` / `rate` / `select` / `slider` / `switch` / `textarea` / `time-picker` / `transfer` / `tree-select` / `upload`
- 数据展示组件：`avatar` / `back-top` / `badge` / `calendar` / `card` / `collapse` / `comment` / `image` / `list` / `progress` / `qrcode` / `range-input` / `select-input` / `skeleton` / `statistic` / `table` / `tag-input` / `tag` / `timeline` / `tooltip` / `tree` / `swiper` / `watermark`
- 消息提示组件：`alert` / `dialog` / `drawer` / `loading` / `message` / `notification` / `popconfirm` / `popup`

- React 中指定的子组件用法：
  - `layout`：`aside` / `header` / `content`
  - `collapse`：`panel`

## 2. 移动端组件

- 基础组件：`button` / `divider` / `fab` / `icon` / `layout` / `link`
- 导航组件：`back-top` / `drawer` / `indexes` / `navbar` / `side-bar` / `steps` / `tab-bar` / `tabs`
- 表单组件：`calendar` / `cascader` / `checkbox` / `color-picker` / `date-time-picker` / `form` / `input` / `picker` / `radio` / `rate` / `search` / `slider` / `stepper` / `switch` / `textarea` / `tree-select` / `upload`
- 数据展示组件：`avatar` / `badge` / `cell` / `collapse` / `count-down` / `empty` / `footer` / `grid` / `image-viewer` / `image` / `list` / `progress` / `qrcode` / `result` / `skeleton` / `sticky` / `swiper` / `table` / `tag` / `watermark`
- 消息提示组件：`action-sheet` / `dialog` / `dropdown-menu` / `guide` / `loading` / `message` / `notice-bar` / `overlay` / `popover` / `popup` / `pull-down-refresh` / `swipe-cell` / `toast`

**注意**：`MiniProgram/UniApp` 框架不支持 `form`、`list`、`table` 组件，仅`Vue/React` 移动端框架支持。

## 2.1 移动端父子组件关系

以下父子组件关系适用于所有移动端框架（Vue/React/MiniProgram/UniApp）：

- `row`：`col`
- `indexes`：`indexes-anchor`
- `side-bar`：`side-bar-item`
- `steps`：`step-item`
- `tab-bar`：`tab-bar-item`
- `tabs`：`tab-panel`
- `checkbox-group`：`checkbox`
- `radio-group`：`radio`
- `avatar-group`：`avatar`
- `cell-group`：`cell`
- `collapse`：`collapse-panel`
- `grid`：`grid-item`
- `dropdown-menu`：`dropdown-item`

**仅适用于 Vue/React 移动端框架**：

- `swiper`：`swiper-item`

**仅适用于 MiniProgram/UniApp 框架**：

- `picker`：`picker-item`
- `swiper`：`swiper-nav`（仅作为导航指示器，不是轮播项容器）