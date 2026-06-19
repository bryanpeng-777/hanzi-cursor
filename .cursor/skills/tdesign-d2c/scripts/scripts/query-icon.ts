import { DOCS_BASE_URL } from ".";

export default async function queryIcon(keywords: string[]) {
  const iconMap = `${DOCS_BASE_URL}/icons.json`;
  const response = await fetch(iconMap);
  if (!response.ok) {
    throw new Error(`Failed to fetch icons from ${iconMap}`);
  }
  const icons: string[] = await response.json();

  const lowerCaseKeywords = keywords.map((keyword) => keyword.toLowerCase());

  const matchedIcons = icons.filter((iconName) => {
    const lowerCaseIconName = iconName.toLowerCase();

    return lowerCaseKeywords.some((keyword) => {
      const regex = new RegExp(`\\b${keyword}\\b`, "i"); // 确保关键词是完整单词
      return regex.test(lowerCaseIconName);
    });
  });

  return matchedIcons;
}

const args = process.argv.slice(2);
const keywords = args[0] ? args[0].split(",") : [];

if (keywords.length === 0) {
  console.error("Usage: tsx query_icon.ts <keywords>");
  process.exit(1);
}

queryIcon(keywords)
  .then((icons) => {
    if (icons.length === 0) {
      console.log("No icons found for the given keywords.");
    } else {
      console.log(icons);
    }
  })
  .catch((err) => {
    console.error("Error:", err);
    process.exit(1);
  });
