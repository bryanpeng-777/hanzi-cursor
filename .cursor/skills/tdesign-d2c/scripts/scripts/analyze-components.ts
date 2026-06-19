import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// 获取当前文件的目录名（ES模块兼容）
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 获取命令行参数
const inputDir = path.join(__dirname, '../_design-context', process.argv[2] || '');

// 确保输入目录是绝对路径
const absoluteInputDir = path.isAbsolute(inputDir) ? inputDir : path.join(process.cwd(), inputDir);


// 组件信息接口定义
interface ComponentInfo {
  componentName: string;
  style?: string;
  src?: string;
  props?: Record<string, string>;
  children?: ComponentInfo[];
}

// 检查输入目录是否存在
if (!fs.existsSync(absoluteInputDir)) {
  console.error(`输入目录不存在: ${absoluteInputDir}`);
  process.exit(1);
}

// 检查是否直接包含 figma.html
const directHtmlPath = path.join(absoluteInputDir, 'figma.html');
const hasDirectHtml = fs.existsSync(directHtmlPath);

if (hasDirectHtml) {
  // 直接处理当前目录的 figma.html
  console.log(`正在处理: ${directHtmlPath}`);
  
  const htmlContent = fs.readFileSync(directHtmlPath, 'utf8');

  // 解析 HTML 并提取带有 data-* 属性的节点
  const components = parseHTMLToComponents(htmlContent);
  const componentsInfo: { layerName: string; components: ComponentInfo[] } = {
    layerName: path.basename(absoluteInputDir),
    components,
  };

  // 保存组件信息到 JSON 文件
  const componentInfoFile = path.join(absoluteInputDir, 'component-info.json');
  fs.writeFileSync(componentInfoFile, JSON.stringify(componentsInfo, null, 2), 'utf8');

  console.log(`已生成: ${componentInfoFile}`);
  console.log(`找到 ${components.length} 个带有 data-* 属性的组件`);
} else {
  // 读取分离的 HTML 文件（子目录模式）
  const layerDirs = fs.readdirSync(absoluteInputDir).filter((dirName: string) => {
    const dirPath = path.join(absoluteInputDir, dirName);
    return fs.statSync(dirPath).isDirectory();
  });

  console.log('找到的层目录:', layerDirs);

  // 分析每个 HTML 文件
  layerDirs.forEach((dirName: string) => {
    const layerDir = path.join(absoluteInputDir, dirName);
    const htmlFilePath = path.join(layerDir, 'figma.html');
    
    if (fs.existsSync(htmlFilePath)) {
      console.log(`正在处理: ${htmlFilePath}`);
      
      const htmlContent = fs.readFileSync(htmlFilePath, 'utf8');

      // 解析 HTML 并提取带有 data-* 属性的节点
      const components = parseHTMLToComponents(htmlContent);
      const componentsInfo: { layerName: string; components: ComponentInfo[] } = {
        layerName: dirName,
        components,
      };

      // 保存组件信息到 JSON 文件
      const layerComponentInfoFile = path.join(layerDir, 'component-info.json');
      fs.writeFileSync(layerComponentInfoFile, JSON.stringify(componentsInfo, null, 2), 'utf8');

      console.log(`已生成: ${layerComponentInfoFile}`);
      console.log(`找到 ${components.length} 个带有 data-* 属性的组件`);
    } else {
      console.warn(`figma.html 文件不存在: ${htmlFilePath}`);
    }
  });
}

console.log('处理完成!');

// 解析 HTML 为组件树
function parseHTMLToComponents(html: string): ComponentInfo[] {
  const components: ComponentInfo[] = [];
  let position = 0;

  while (position < html.length) {
    // 查找下一个开始标签
    const tagStart = html.indexOf('<', position);
    if (tagStart === -1) break;

    // 检查是否是结束标签
    if (html[tagStart + 1] === '/') {
      position = tagStart + 1;
      continue;
    }

    // 查找标签结束位置
    const tagEnd = html.indexOf('>', tagStart);
    if (tagEnd === -1) break;

    // 检查是否是自闭合标签
    const isSelfClosing = html[tagEnd - 1] === '/';

    // 提取标签内容
    const tagContent = html.substring(tagStart + 1, tagEnd);
    const spaceIndex = tagContent.indexOf(' ');
    const tagName = spaceIndex > 0 ? tagContent.substring(0, spaceIndex) : tagContent;
    const attributes = spaceIndex > 0 ? tagContent.substring(spaceIndex + 1) : '';

    const resolvedComponentName = resolveComponentName(attributes);
    if (resolvedComponentName !== null) {
      if (isSelfClosing) {
        // 处理自闭合标签
        const props = extractDataAttributes(attributes);
        cleanupProps(props);

        const component = buildComponent(resolvedComponentName, props, attributes);
        components.push(component);
        position = tagEnd + 1;
      } else {
        // 处理普通标签，查找对应的结束标签
        const closingTag = `</${tagName}>`;
        const closingTagStart = findMatchingClosingTag(html, tagStart, tagName);

        if (closingTagStart !== -1) {
          // 提取 innerHTML
          const innerHTML = html.substring(tagEnd + 1, closingTagStart);

          // 提取所有 data-* 属性作为 props
          const props = extractDataAttributes(attributes);
          cleanupProps(props);

          const component = buildComponent(resolvedComponentName, props, attributes);

          // 递归解析子节点
          if (innerHTML && innerHTML.trim().length > 0) {
            const children = parseHTMLToComponents(innerHTML);
            if (children.length > 0) {
              component.children = children;
            }
          }

          components.push(component);
          position = closingTagStart + closingTag.length;
        } else {
          position = tagEnd + 1;
        }
      }
    } else {
      // 节点本身不是组件（无 data-component-name），穿透继续遍历其子节点
      if (!isSelfClosing) {
        const closingTagStart = findMatchingClosingTag(html, tagStart, tagName);
        if (closingTagStart !== -1) {
          const innerHTML = html.substring(tagEnd + 1, closingTagStart);
          if (innerHTML && innerHTML.trim().length > 0) {
            const children = parseHTMLToComponents(innerHTML);
            components.push(...children);
          }
          position = closingTagStart + `</${tagName}>`.length;
        } else {
          position = tagEnd + 1;
        }
      } else {
        position = tagEnd + 1;
      }
    }
  }

  return components;
}

// 查找匹配的结束标签
function findMatchingClosingTag(html: string, startPos: number, tagName: string): number {
  const openTag = `<${tagName}`;
  const closeTag = `</${tagName}>`;
  let depth = 1;
  let pos = html.indexOf('>', startPos) + 1;
  
  while (pos < html.length && depth > 0) {
    const nextOpen = html.indexOf(openTag, pos);
    const nextClose = html.indexOf(closeTag, pos);
    
    if (nextClose === -1) {
      return -1; // 没有找到结束标签
    }
    
    if (nextOpen !== -1 && nextOpen < nextClose) {
      // 检查这是否是同名标签的开始
      const charAfterTag = html[nextOpen + openTag.length];
      if (charAfterTag === ' ' || charAfterTag === '>') {
        depth++;
      }
      pos = nextOpen + openTag.length;
    } else {
      depth--;
      if (depth === 0) {
        return nextClose;
      }
      pos = nextClose + closeTag.length;
    }
  }
  
  return -1;
}

// 提取 data-x 属性，提取组件的变体
function extractDataAttributes(attr: string): Record<string, string> {
  const processedAttrs: Record<string, string> = {};

  const dataPattern = /(data-[^=\s]+)=["']([^"']*)["']/g;
  let match: RegExpExecArray | null;

  while ((match = dataPattern.exec(attr)) !== null) {
    const fullAttrName = match[1];
    const attrValue = match[2];

    // 跳过 data-name 和 data-component-name
    if (
      fullAttrName === 'data-name' ||
      fullAttrName === 'data-component-name'
    ) {
      continue;
    }

    const keyPart = fullAttrName
      .replace(/^data-/, '')
      .replace(/-/g, ' ');

    if (keyPart) {
      processedAttrs[keyPart] = attrValue;
    }
  }

  return processedAttrs;
}

// 提取 data-component-name 的值
function extractDataComponentName(attr: string): string | null {
  const pattern = /data-component-name=["']([^"']*)["']/;
  const match = attr.match(pattern);

  if (match) {
    return match[1];
  }

  return null;
}

// 提取 data-name 的值
function extractDataName(attr: string): string | null {
  const pattern = /data-name=["']([^"']*)["']/;
  const match = attr.match(pattern);
  return match ? match[1] : null;
}

// 解析最终的 componentName
function resolveComponentName(attr: string): string | null {
  // 1. 优先使用 data-component-name
  const fromComponentName = extractDataComponentName(attr);
  if (fromComponentName !== null) {
    return fromComponentName;
  }

  // 2. Hack：当 data-name 包含 "table"（不区分大小写）或中文 "表格" 时，也视为组件
  // (表格通常会被拆分使用)
  const dataName = extractDataName(attr);
  if (dataName !== null) {
    if (dataName.toLowerCase().includes('table') || dataName.includes('表格')) {
      return dataName;
    }
  }

  return null;
}

// 清洗 props
function cleanupProps(props: Record<string, string>): void {
  const FIGMA_NODE_ID_PATTERN = /^[A-Za-z]?\d+:\d+(?:;\d+:\d+)*$/;

  for (const key of Object.keys(props)) {
    const value = props[key];
    // 1. 移除 value 为 Figma 节点 ID 形式的属性（如 suffix="1:53"）
    // 2. 移除 value 为 "n/a" 的属性
    if (FIGMA_NODE_ID_PATTERN.test(value) || value.trim().toLowerCase() === 'n/a') {
      delete props[key];
    }
  }
}

// 提取单个指定属性
function extractAttribute(attr: string, name: string): string | undefined {
  const pattern = new RegExp(`(?:^|\\s)${name}=["']([^"']*)["']`);
  const match = attr.match(pattern);
  return match ? match[1] : undefined;
}

// 构造 ComponentInfo
function buildComponent(
  componentName: string,
  props: Record<string, string>,
  attributes: string,
): ComponentInfo {

  // 非 data-* 属性，从原始属性字符串里取
  const style = extractAttribute(attributes, 'style');
  const src = extractAttribute(attributes, 'src');

  const component: ComponentInfo = { componentName } as ComponentInfo;
  if (style !== undefined) component.style = style;
  if (src !== undefined) component.src = src;
  if (Object.keys(props).length > 0) component.props = props;
  return component;
}
